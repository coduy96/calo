# iCloud Sync (CKSyncEngine) Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Give every Voidpen user automatic, always-on, free, full-fidelity (incl. photos) sync of their food/weight/body-fat/profile/chat data to their private CloudKit database, surviving reinstall and syncing live across devices.

**Architecture:** Keep UserDefaults + on-disk JPEGs as the local source of truth (zero data migration). Add a thin sync layer: each model gains a `modifiedAt` timestamp; stores gain additive sync hooks (outbound) and `applyCloud*` methods (inbound, last-writer-wins, no echo); a `CloudSyncCoordinator` wraps `CKSyncEngine` over one custom record zone in the private DB; per-type `SyncAdapter`s map models ↔ `CKRecord` (photos via `CKAsset`).

**Tech Stack:** Swift, SwiftUI, `@Observable` stores, CloudKit / `CKSyncEngine` (iOS 17+), Swift Testing (`import Testing`, `@Test`, `#expect`). Deployment target iOS 17.6.

**Spec:** `docs/superpowers/specs/2026-06-08-icloud-sync-design.md`

---

## Conventions used throughout

- **CloudKit container:** `iCloud.com.cotrinhhienduy.calorietracker`
- **Custom zone name:** `VoidpenZone`
- **Record types & recordName prefixes** (recordName = `<prefix>_<uuid>` so a logged food entry and a favorite with the same UUID never collide on `CKRecord.ID`):

  | Record type | Prefix | Source |
  | --- | --- | --- |
  | `FoodEntry` | `food_` | logged `FoodEntry` |
  | `FoodFavorite` | `fav_` | favorite `FoodEntry` |
  | `WeightEntry` | `weight_` | `WeightEntry` |
  | `BodyFatEntry` | `bodyfat_` | `BodyFatEntry` |
  | `ChatThread` | `chat_` | `ChatThread` |
  | `UserProfile` | (fixed name `profile`) | `UserProfile` singleton |

- **`modifiedAt`:** added as `Date?` on every synced model (missing key → `nil` → treated as `.distantPast`). `ChatThread` reuses its existing non-optional `updatedAt`.
- **Conflict policy:** last-writer-wins. Helper `effectiveModifiedAt: Date { modifiedAt ?? .distantPast }`.
- **All new sync code** lives under `ios/calorietracker/Services/Sync/`.
- **Tests** live in `ios/calorietrackerTests/` and use Swift Testing.
- **Build/test command** (run from `ios/`):
  `xcodebuild test -scheme calorietracker -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:calorietrackerTests/<SuiteName>`
  (Adjust simulator name to one present via `xcrun simctl list devices`.)

> **Note on CKSyncEngine code (Phase 5):** `CKSyncEngine` is iOS 17+. Before implementing Phase 5, fetch current API docs via context7 (`resolve-library-id` → CloudKit / `query-docs` "CKSyncEngine delegate handleEvent nextRecordZoneChangeBatch") and confirm signatures against the installed SDK. The code below is accurate to the iOS 17–18 API; verify enum case names against the SDK before trusting them.

---

## Phase 0 — Dead-code cleanup

The repo has unwired, naive scaffolding that the new layer replaces. Remove it first so nothing references the old "fetch-all / cloud-always-wins" logic.

### Task 0.1: Delete the naive CloudKitService and merge methods

**Files:**
- Delete: `ios/calorietracker/Services/CloudKitService.swift`
- Modify: `ios/calorietracker/Stores/FoodStore.swift` (remove `mergeWithCloudEntries`, lines ~316–324)
- Modify: `ios/calorietracker/Stores/WeightStore.swift` (remove `mergeWithCloudEntries`, lines ~100–107)

- [ ] **Step 1: Confirm nothing references them**

Run: `cd ios && grep -rn "CloudKitService\|mergeWithCloudEntries" calorietracker --include="*.swift"`
Expected: only the definitions themselves (no call sites).

- [ ] **Step 2: Delete the file and methods**

```bash
rm ios/calorietracker/Services/CloudKitService.swift
```
Then delete the `mergeWithCloudEntries(_:)` method from both `FoodStore.swift` and `WeightStore.swift`.

- [ ] **Step 3: Build to confirm no breakage**

Run: `cd ios && xcodebuild build -scheme calorietracker -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "chore: remove dead/naive CloudKit scaffolding before CKSyncEngine rework"
```

---

## Phase 1 — `modifiedAt` on models (TDD)

Adds the timestamp last-writer-wins depends on. Backward-compatible: existing stored rows lack the key and decode to `nil`.

### Task 1.1: Add `modifiedAt` to `WeightEntry`

**Files:**
- Modify: `ios/calorietracker/Models/WeightEntry.swift`
- Test: `ios/calorietrackerTests/SyncModelTests.swift` (create)

- [ ] **Step 1: Write the failing test**

```swift
import Testing
import Foundation
@testable import calorietracker

struct WeightEntryModifiedAtTests {

    @Test func newEntryHasModifiedAt() {
        let entry = WeightEntry(weightKg: 70)
        #expect(entry.modifiedAt != nil)
    }

    @Test func decodingLegacyDataWithoutModifiedAtYieldsNil() throws {
        // Legacy JSON written before modifiedAt existed.
        let legacy = """
        {"id":"\(UUID().uuidString)","date":\(Date().timeIntervalSinceReferenceDate),"weightKg":72.5}
        """.data(using: .utf8)!
        let entry = try JSONDecoder().decode(WeightEntry.self, from: legacy)
        #expect(entry.modifiedAt == nil)
        #expect(entry.effectiveModifiedAt == .distantPast)
        #expect(entry.weightKg == 72.5)
    }
}
```

- [ ] **Step 2: Run to verify it fails**

Run: `cd ios && xcodebuild test -scheme calorietracker -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:calorietrackerTests/WeightEntryModifiedAtTests`
Expected: FAIL — `value of type 'WeightEntry' has no member 'modifiedAt'`.

- [ ] **Step 3: Add the field**

In `WeightEntry.swift`, add the property, the helper, and the init param (synthesized Codable handles the optional automatically — a missing key decodes to `nil`):

```swift
struct WeightEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    var weightKg: Double
    var photoFilename: String?
    var modifiedAt: Date?

    var effectiveModifiedAt: Date { modifiedAt ?? .distantPast }

    init(id: UUID = UUID(), date: Date = .now, weightKg: Double, photoFilename: String? = nil, modifiedAt: Date? = Date()) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.photoFilename = photoFilename
        self.modifiedAt = modifiedAt
    }
    // ... keep existing computed properties (weightLbs etc.)
}
```

- [ ] **Step 4: Run to verify it passes**

Run: same as Step 2.
Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: add modifiedAt to WeightEntry for LWW sync"
```

### Task 1.2: Add `modifiedAt` to `BodyFatEntry`

**Files:**
- Modify: `ios/calorietracker/Models/BodyFatEntry.swift`
- Test: `ios/calorietrackerTests/SyncModelTests.swift`

- [ ] **Step 1: Write the failing test** (append to `SyncModelTests.swift`)

```swift
struct BodyFatEntryModifiedAtTests {
    @Test func newEntryHasModifiedAt() {
        #expect(BodyFatEntry(bodyFatFraction: 0.2).modifiedAt != nil)
    }
    @Test func legacyDecodesToNil() throws {
        let legacy = """
        {"id":"\(UUID().uuidString)","date":\(Date().timeIntervalSinceReferenceDate),"bodyFatFraction":0.18}
        """.data(using: .utf8)!
        let e = try JSONDecoder().decode(BodyFatEntry.self, from: legacy)
        #expect(e.modifiedAt == nil)
        #expect(e.effectiveModifiedAt == .distantPast)
    }
}
```

- [ ] **Step 2: Run to verify it fails** — Expected: FAIL (no member `modifiedAt`).

- [ ] **Step 3: Add the field**

```swift
struct BodyFatEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    var bodyFatFraction: Double
    var modifiedAt: Date?

    var effectiveModifiedAt: Date { modifiedAt ?? .distantPast }

    init(id: UUID = UUID(), date: Date = .now, bodyFatFraction: Double, modifiedAt: Date? = Date()) {
        self.id = id
        self.date = date
        self.bodyFatFraction = bodyFatFraction
        self.modifiedAt = modifiedAt
    }
    // ... keep existing convenience computed property
}
```

- [ ] **Step 4: Run to verify it passes** — Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: add modifiedAt to BodyFatEntry for LWW sync"
```

### Task 1.3: Add `modifiedAt` to `FoodEntry` (custom Codable)

**Files:**
- Modify: `ios/calorietracker/Models/FoodEntry.swift` (props, CodingKeys, `init`, `init(from:)`, `encode(to:)`)
- Test: `ios/calorietrackerTests/SyncModelTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
struct FoodEntryModifiedAtTests {
    @Test func newEntryHasModifiedAt() {
        let e = FoodEntry(name: "Apple", calories: 95, protein: 0, carbs: 25, fat: 0, source: .manual)
        #expect(e.modifiedAt != nil)
    }
    @Test func roundTripPreservesModifiedAt() throws {
        let stamp = Date(timeIntervalSince1970: 1_700_000_000)
        let e = FoodEntry(name: "Egg", calories: 70, protein: 6, carbs: 0, fat: 5, source: .manual, modifiedAt: stamp)
        let data = try JSONEncoder().encode(e)
        let decoded = try JSONDecoder().decode(FoodEntry.self, from: data)
        #expect(decoded.modifiedAt == stamp)
    }
    @Test func legacyFoodEntryDecodesToNilModifiedAt() throws {
        let id = UUID().uuidString
        let legacy = """
        {"id":"\(id)","name":"Toast","calories":100,"protein":3,"carbs":18,"fat":1,"timestamp":\(Date().timeIntervalSinceReferenceDate),"source":"manual","mealType":"breakfast"}
        """.data(using: .utf8)!
        let e = try JSONDecoder().decode(FoodEntry.self, from: legacy)
        #expect(e.modifiedAt == nil)
        #expect(e.effectiveModifiedAt == .distantPast)
    }
}
```

- [ ] **Step 2: Run to verify it fails** — Expected: FAIL (no member `modifiedAt`).

- [ ] **Step 3: Add the field across the custom Codable**

In `FoodEntry.swift`:
1. Add property after `timestamp`: `var modifiedAt: Date?` and helper `var effectiveModifiedAt: Date { modifiedAt ?? .distantPast }`.
2. Add `modifiedAt: Date? = Date()` as the last `init` parameter and assign `self.modifiedAt = modifiedAt`.
3. Add `case modifiedAt` to `CodingKeys`.
4. In `init(from:)`, add: `modifiedAt = try container.decodeIfPresent(Date.self, forKey: .modifiedAt)`.
5. In `encode(to:)`, add: `try container.encodeIfPresent(modifiedAt, forKey: .modifiedAt)`.

- [ ] **Step 4: Run to verify it passes** — Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: add modifiedAt to FoodEntry custom Codable for LWW sync"
```

### Task 1.4: Add `modifiedAt` to `UserProfile`, bumped in `save()`

**Files:**
- Modify: `ios/calorietracker/Models/UserProfile.swift`
- Test: `ios/calorietrackerTests/SyncModelTests.swift`

- [ ] **Step 1: Write the failing test**

```swift
struct UserProfileModifiedAtTests {
    @Test func saveBumpsModifiedAtOnDisk() throws {
        var p = UserProfile.default
        p.weightKg = 81
        p.save()
        let loaded = try #require(UserProfile.load())
        #expect(loaded.modifiedAt != nil)
        #expect(loaded.weightKg == 81)
    }
}
```

- [ ] **Step 2: Run to verify it fails** — Expected: FAIL (no member `modifiedAt`).

- [ ] **Step 3: Add the field + bump on save**

1. Add `var modifiedAt: Date?` to the struct's stored properties.
2. Add `modifiedAt: Date? = nil` as the last parameter of `UserProfile.init(...)` and assign it (keeps `.default` and all positional call sites compiling).
3. Add helper `var effectiveModifiedAt: Date { modifiedAt ?? .distantPast }`.
4. Change `save()` to stamp a copy so every profile write bumps the timestamp at one chokepoint:

```swift
func save() {
    var copy = self
    copy.modifiedAt = Date()
    if let data = try? JSONEncoder().encode(copy) {
        UserDefaults.standard.set(data, forKey: "userProfile")
        NotificationCenter.default.post(name: .userProfileDidChange, object: nil)
    }
}

/// Save WITHOUT bumping modifiedAt — used when applying a cloud profile so the
/// incoming timestamp is preserved (otherwise it would always look "newer").
func savePreservingTimestamp() {
    if let data = try? JSONEncoder().encode(self) {
        UserDefaults.standard.set(data, forKey: "userProfile")
        NotificationCenter.default.post(name: .userProfileDidChange, object: nil)
    }
}
```

- [ ] **Step 4: Run to verify it passes** — Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: add modifiedAt to UserProfile, bump in save() for LWW sync"
```

---

## Phase 2 — Store sync hooks + inbound apply (TDD)

Stores gain an **additive** outbound hook (separate from the HealthKit closures) and inbound `applyCloud*` methods that do last-writer-wins **without** echoing back to the cloud.

### Task 2.1: Define the shared `SyncMutation` type

**Files:**
- Create: `ios/calorietracker/Services/Sync/SyncMutation.swift`
- Test: `ios/calorietrackerTests/SyncMutationTests.swift` (create)

- [ ] **Step 1: Write the failing test**

```swift
import Testing
import Foundation
@testable import calorietracker

struct SyncMutationTests {
    @Test func recordNameNamespacesByKind() {
        let id = UUID()
        #expect(SyncRecordKind.food.recordName(for: id) == "food_\(id.uuidString)")
        #expect(SyncRecordKind.favorite.recordName(for: id) == "fav_\(id.uuidString)")
        #expect(SyncRecordKind.weight.recordName(for: id) == "weight_\(id.uuidString)")
    }
    @Test func parsesKindAndIDFromRecordName() {
        let id = UUID()
        let parsed = SyncRecordKind.parse(recordName: "bodyfat_\(id.uuidString)")
        #expect(parsed?.kind == .bodyFat)
        #expect(parsed?.id == id)
    }
    @Test func profileHasFixedRecordName() {
        #expect(SyncRecordKind.profile.fixedRecordName == "profile")
    }
}
```

- [ ] **Step 2: Run to verify it fails** — Expected: FAIL (no type `SyncRecordKind`).

- [ ] **Step 3: Implement**

```swift
import Foundation

/// The kinds of records Voidpen syncs. Each maps to a CloudKit record type and
/// a recordName prefix so the same UUID can exist as two kinds (e.g. a logged
/// food entry and a favorite) without colliding on CKRecord.ID.
enum SyncRecordKind: String, CaseIterable {
    case food, favorite, weight, bodyFat, chat, profile

    var recordType: String {
        switch self {
        case .food: return "FoodEntry"
        case .favorite: return "FoodFavorite"
        case .weight: return "WeightEntry"
        case .bodyFat: return "BodyFatEntry"
        case .chat: return "ChatThread"
        case .profile: return "UserProfile"
        }
    }

    var prefix: String {
        switch self {
        case .food: return "food_"
        case .favorite: return "fav_"
        case .weight: return "weight_"
        case .bodyFat: return "bodyfat_"
        case .chat: return "chat_"
        case .profile: return "profile"
        }
    }

    /// The profile is a singleton with a fixed recordName.
    var fixedRecordName: String { "profile" }

    func recordName(for id: UUID) -> String {
        self == .profile ? fixedRecordName : "\(prefix)\(id.uuidString)"
    }

    static func kind(forRecordType recordType: String) -> SyncRecordKind? {
        allCases.first { $0.recordType == recordType }
    }

    /// Parse a recordName back into (kind, id). Returns nil for the profile
    /// singleton (use kind(forRecordType:) there) or malformed names.
    static func parse(recordName: String) -> (kind: SyncRecordKind, id: UUID)? {
        for kind in allCases where kind != .profile {
            if recordName.hasPrefix(kind.prefix),
               let id = UUID(uuidString: String(recordName.dropFirst(kind.prefix.count))) {
                return (kind, id)
            }
        }
        return nil
    }
}

/// A local change a store reports outbound to the sync coordinator.
struct SyncMutation {
    let kind: SyncRecordKind
    let id: UUID
    let deleted: Bool
}
```

- [ ] **Step 4: Run to verify it passes** — Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: add SyncRecordKind + SyncMutation sync identity types"
```

### Task 2.2: FoodStore — outbound hook + inbound apply (LWW)

**Files:**
- Modify: `ios/calorietracker/Stores/FoodStore.swift`
- Test: `ios/calorietrackerTests/FoodStoreSyncTests.swift` (create)

- [ ] **Step 1: Write the failing test**

```swift
import Testing
import Foundation
@testable import calorietracker

@MainActor
struct FoodStoreSyncTests {

    private func freshStore() -> FoodStore {
        UserDefaults.standard.removeObject(forKey: "foodEntries")
        UserDefaults.standard.removeObject(forKey: "favoriteFoodEntries")
        return FoodStore()
    }

    @Test func addEntryEmitsSyncMutation() {
        let store = freshStore()
        var captured: SyncMutation?
        store.onSyncMutation = { captured = $0 }
        let e = FoodEntry(name: "Banana", calories: 105, protein: 1, carbs: 27, fat: 0, source: .manual)
        store.addEntry(e)
        #expect(captured?.kind == .food)
        #expect(captured?.id == e.id)
        #expect(captured?.deleted == false)
    }

    @Test func deleteEntryEmitsDeletedMutation() {
        let store = freshStore()
        let e = FoodEntry(name: "Banana", calories: 105, protein: 1, carbs: 27, fat: 0, source: .manual)
        store.addEntry(e)
        var captured: SyncMutation?
        store.onSyncMutation = { captured = $0 }
        store.deleteEntry(e)
        #expect(captured?.deleted == true)
        #expect(captured?.id == e.id)
    }

    @Test func applyCloudUpsertInsertsNewEntry() {
        let store = freshStore()
        let e = FoodEntry(name: "Cloud Apple", calories: 95, protein: 0, carbs: 25, fat: 0, source: .manual)
        store.applyCloudUpsert(e)
        #expect(store.entries.contains { $0.id == e.id })
    }

    @Test func applyCloudUpsertDoesNotEcho() {
        let store = freshStore()
        var echoed = false
        store.onSyncMutation = { _ in echoed = true }
        store.applyCloudUpsert(FoodEntry(name: "x", calories: 1, protein: 0, carbs: 0, fat: 0, source: .manual))
        #expect(echoed == false)
    }

    @Test func applyCloudUpsertOlderDoesNotClobberNewerLocal() {
        let store = freshStore()
        let id = UUID()
        let newer = FoodEntry(id: id, name: "Local new", calories: 200, protein: 0, carbs: 0, fat: 0, source: .manual, modifiedAt: Date())
        store.applyCloudUpsert(newer)
        let older = FoodEntry(id: id, name: "Cloud old", calories: 999, protein: 0, carbs: 0, fat: 0, source: .manual, modifiedAt: Date(timeIntervalSince1970: 0))
        store.applyCloudUpsert(older)
        #expect(store.entries.first { $0.id == id }?.name == "Local new")
    }

    @Test func applyCloudDeleteRemovesEntry() {
        let store = freshStore()
        let e = FoodEntry(name: "ToDelete", calories: 1, protein: 0, carbs: 0, fat: 0, source: .manual)
        store.applyCloudUpsert(e)
        store.applyCloudDelete(id: e.id)
        #expect(!store.entries.contains { $0.id == e.id })
    }
}
```

- [ ] **Step 2: Run to verify it fails** — Expected: FAIL (no member `onSyncMutation` / `applyCloudUpsert`).

- [ ] **Step 3: Implement in `FoodStore`**

Add the hook property near the other callbacks:

```swift
/// Outbound sync hook. Additive — distinct from onEntryAdded/Updated/Deleted
/// (those are owned by HealthKit). Fired ONLY on user-driven mutations.
var onSyncMutation: ((SyncMutation) -> Void)?
```

In `addEntry`, after `onEntryAdded?(entry)`:
```swift
onSyncMutation?(SyncMutation(kind: .food, id: entry.id, deleted: false))
```
In `updateEntry`, set `entry.modifiedAt = Date()` right after `var entry = entry`, and after `onEntryUpdated?(entry)`:
```swift
onSyncMutation?(SyncMutation(kind: .food, id: entry.id, deleted: false))
```
In `addEntry`, also set `entry.modifiedAt = Date()` after `var entry = entry`.
In `deleteEntry`, after `onEntryDeleted?(id)`:
```swift
onSyncMutation?(SyncMutation(kind: .food, id: id, deleted: true))
```

Add inbound methods (no echo, LWW):
```swift
/// Apply a food entry received from iCloud. Last-writer-wins by modifiedAt.
/// Never emits onSyncMutation (no echo). Refreshes UI via onEntriesChanged.
func applyCloudUpsert(_ incoming: FoodEntry) {
    if let idx = entries.firstIndex(where: { $0.id == incoming.id }) {
        guard incoming.effectiveModifiedAt >= entries[idx].effectiveModifiedAt else { return }
        entries[idx] = incoming
    } else {
        entries.append(incoming)
    }
    saveEntries()
    onEntriesChanged?()
}

func applyCloudDelete(id: UUID) {
    guard entries.contains(where: { $0.id == id }) else { return }
    if let entry = entries.first(where: { $0.id == id }),
       let filename = entry.imageFilename,
       !isImageStillReferenced(filename: filename, excludingEntryID: id) {
        FoodImageStore.shared.delete(filename: filename)
    }
    entries.removeAll { $0.id == id }
    saveEntries()
    onEntriesChanged?()
}
```

> The favorites array gets the same treatment in Task 2.6.

- [ ] **Step 4: Run to verify it passes** — Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: FoodStore outbound sync hook + LWW inbound apply"
```

### Task 2.3: WeightStore — hook + inbound apply

**Files:**
- Modify: `ios/calorietracker/Stores/WeightStore.swift`
- Test: `ios/calorietrackerTests/WeightStoreSyncTests.swift` (create)

- [ ] **Step 1: Write the failing test**

```swift
import Testing
import Foundation
@testable import calorietracker

@MainActor
struct WeightStoreSyncTests {
    private func freshStore() -> WeightStore {
        UserDefaults.standard.removeObject(forKey: "weightEntries")
        return WeightStore()
    }
    @Test func addEmitsMutation() {
        let store = freshStore()
        var m: SyncMutation?
        store.onSyncMutation = { m = $0 }
        let e = WeightEntry(weightKg: 70)
        store.addEntry(e)
        #expect(m?.kind == .weight); #expect(m?.id == e.id); #expect(m?.deleted == false)
    }
    @Test func deleteEmitsDeleted() {
        let store = freshStore()
        let e = WeightEntry(weightKg: 70); store.addEntry(e)
        var m: SyncMutation?; store.onSyncMutation = { m = $0 }
        store.deleteEntry(e)
        #expect(m?.deleted == true)
    }
    @Test func applyCloudUpsertNoEchoAndInserts() {
        let store = freshStore()
        var echoed = false; store.onSyncMutation = { _ in echoed = true }
        let e = WeightEntry(weightKg: 71)
        store.applyCloudUpsert(e)
        #expect(store.entries.contains { $0.id == e.id }); #expect(echoed == false)
    }
    @Test func applyCloudUpsertLWW() {
        let store = freshStore()
        let id = UUID()
        store.applyCloudUpsert(WeightEntry(id: id, weightKg: 80, modifiedAt: Date()))
        store.applyCloudUpsert(WeightEntry(id: id, weightKg: 60, modifiedAt: Date(timeIntervalSince1970: 0)))
        #expect(store.entries.first { $0.id == id }?.weightKg == 80)
    }
    @Test func applyCloudDeleteRemoves() {
        let store = freshStore()
        let e = WeightEntry(weightKg: 70); store.applyCloudUpsert(e)
        store.applyCloudDelete(id: e.id)
        #expect(!store.entries.contains { $0.id == e.id })
    }
}
```

- [ ] **Step 2: Run to verify it fails** — Expected: FAIL.

- [ ] **Step 3: Implement in `WeightStore`**

Add `var onSyncMutation: ((SyncMutation) -> Void)?`.
In `addEntry`: set `var entry = entry; entry.modifiedAt = Date()` (append the stamped copy), and after `onEntryAdded?(entry)` add `onSyncMutation?(SyncMutation(kind: .weight, id: entry.id, deleted: false))`.
In `deleteEntry`: after `onEntryDeleted?(id)` add `onSyncMutation?(SyncMutation(kind: .weight, id: id, deleted: true))`.

> Leave `importExternalEntries` (HK backfill) WITHOUT a sync emit — Task 2.7 makes it emit a batch so HK-imported history also syncs. For now it stays silent.

Inbound:
```swift
func applyCloudUpsert(_ incoming: WeightEntry) {
    if let idx = entries.firstIndex(where: { $0.id == incoming.id }) {
        guard incoming.effectiveModifiedAt >= entries[idx].effectiveModifiedAt else { return }
        entries[idx] = incoming
    } else {
        entries.append(incoming)
    }
    saveEntries()
}
func applyCloudDelete(id: UUID) {
    guard let entry = entries.first(where: { $0.id == id }) else { return }
    if let filename = entry.photoFilename { WeightPhotoStore.shared.delete(filename: filename) }
    entries.removeAll { $0.id == id }
    saveEntries()
}
```

- [ ] **Step 4: Run to verify it passes** — Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: WeightStore outbound sync hook + LWW inbound apply"
```

### Task 2.4: BodyFatStore — hook + inbound apply

**Files:**
- Modify: `ios/calorietracker/Stores/BodyFatStore.swift`
- Test: `ios/calorietrackerTests/BodyFatStoreSyncTests.swift` (create)

- [ ] **Step 1: Write the failing test** (mirror Task 2.3 with `kind == .bodyFat`, key `"bodyFatEntries"`, `BodyFatEntry(bodyFatFraction:)`, comparing `bodyFatFraction`).

```swift
import Testing
import Foundation
@testable import calorietracker

@MainActor
struct BodyFatStoreSyncTests {
    private func freshStore() -> BodyFatStore {
        UserDefaults.standard.removeObject(forKey: "bodyFatEntries")
        return BodyFatStore()
    }
    @Test func addEmitsMutation() {
        let store = freshStore()
        var m: SyncMutation?; store.onSyncMutation = { m = $0 }
        let e = BodyFatEntry(bodyFatFraction: 0.2); store.addEntry(e)
        #expect(m?.kind == .bodyFat); #expect(m?.deleted == false)
    }
    @Test func applyCloudUpsertLWWNoEcho() {
        let store = freshStore()
        var echoed = false; store.onSyncMutation = { _ in echoed = true }
        let id = UUID()
        store.applyCloudUpsert(BodyFatEntry(id: id, bodyFatFraction: 0.25, modifiedAt: Date()))
        store.applyCloudUpsert(BodyFatEntry(id: id, bodyFatFraction: 0.99, modifiedAt: Date(timeIntervalSince1970: 0)))
        #expect(store.entries.first { $0.id == id }?.bodyFatFraction == 0.25)
        #expect(echoed == false)
    }
    @Test func applyCloudDeleteRemoves() {
        let store = freshStore()
        let e = BodyFatEntry(bodyFatFraction: 0.2); store.applyCloudUpsert(e)
        store.applyCloudDelete(id: e.id)
        #expect(!store.entries.contains { $0.id == e.id })
    }
}
```

- [ ] **Step 2: Run to verify it fails** — Expected: FAIL.

- [ ] **Step 3: Implement** — add `var onSyncMutation`, stamp `modifiedAt = Date()` on add, emit on add/delete (`kind: .bodyFat`), and add `applyCloudUpsert`/`applyCloudDelete` mirroring Task 2.3 (no photo handling — body fat has no photos).

- [ ] **Step 4: Run to verify it passes** — Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: BodyFatStore outbound sync hook + LWW inbound apply"
```

### Task 2.5: ChatStore — hook + inbound apply (reuses `updatedAt`)

**Files:**
- Modify: `ios/calorietracker/Stores/ChatStore.swift`
- Test: `ios/calorietrackerTests/ChatStoreSyncTests.swift` (create)

- [ ] **Step 1: Write the failing test**

```swift
import Testing
import Foundation
@testable import calorietracker

@MainActor
struct ChatStoreSyncTests {
    private func freshStore() -> ChatStore {
        UserDefaults.standard.removeObject(forKey: "coachChatThreads")
        return ChatStore()
    }
    @Test func appendEmitsMutation() {
        let store = freshStore()
        let t = store.createDraftThread()
        var m: SyncMutation?; store.onSyncMutation = { m = $0 }
        store.append(ChatMessage(role: .user, content: "hi"), to: t.id)
        #expect(m?.kind == .chat); #expect(m?.id == t.id); #expect(m?.deleted == false)
    }
    @Test func deleteEmitsDeleted() {
        let store = freshStore()
        let t = store.createDraftThread()
        var m: SyncMutation?; store.onSyncMutation = { m = $0 }
        store.delete(threadID: t.id)
        #expect(m?.deleted == true); #expect(m?.id == t.id)
    }
    @Test func applyCloudUpsertLWWByUpdatedAtNoEcho() {
        let store = freshStore()
        var echoed = false; store.onSyncMutation = { _ in echoed = true }
        let id = UUID()
        let newer = ChatThread(id: id, title: "New", messages: [], createdAt: .now, updatedAt: Date())
        let older = ChatThread(id: id, title: "Old", messages: [], createdAt: .now, updatedAt: Date(timeIntervalSince1970: 0))
        store.applyCloudUpsert(newer)
        store.applyCloudUpsert(older)
        #expect(store.thread(id: id)?.title == "New")
        #expect(echoed == false)
    }
    @Test func applyCloudDeleteRemoves() {
        let store = freshStore()
        let id = UUID()
        store.applyCloudUpsert(ChatThread(id: id, title: "x", messages: [], createdAt: .now, updatedAt: .now))
        store.applyCloudDelete(id: id)
        #expect(store.thread(id: id) == nil)
    }
}
```

- [ ] **Step 2: Run to verify it fails** — Expected: FAIL.

- [ ] **Step 3: Implement in `ChatStore`**

Add `var onSyncMutation: ((SyncMutation) -> Void)?`. Emit `kind: .chat` in `append`, `replaceLastAssistant`, `rename`, `createDraftThread` (deleted:false) and in `delete` / `deleteIfEmpty` (deleted:true). Use the thread id. Inbound (LWW by `updatedAt`, no echo):

```swift
func applyCloudUpsert(_ incoming: ChatThread) {
    if let idx = threads.firstIndex(where: { $0.id == incoming.id }) {
        guard incoming.updatedAt >= threads[idx].updatedAt else { return }
        threads[idx] = incoming
    } else {
        threads.append(incoming)
    }
    save()
}
func applyCloudDelete(id: UUID) {
    guard threads.contains(where: { $0.id == id }) else { return }
    threads.removeAll { $0.id == id }
    save()
}
```

> Skip emitting for `createDraftThread` if you prefer not to sync empty drafts; emitting is harmless (an empty thread is hidden from `visibleThreads` on every device).

- [ ] **Step 4: Run to verify it passes** — Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: ChatStore outbound sync hook + LWW inbound apply"
```

### Task 2.6: FoodStore favorites — hook + inbound apply

**Files:**
- Modify: `ios/calorietracker/Stores/FoodStore.swift`
- Test: `ios/calorietrackerTests/FoodStoreSyncTests.swift` (append)

- [ ] **Step 1: Write the failing test**

```swift
extension FoodStoreSyncTests {
    @Test func toggleFavoriteEmitsFavoriteMutation() {
        let store = freshStore()
        let e = FoodEntry(name: "Fav", calories: 50, protein: 0, carbs: 0, fat: 0, source: .manual)
        var m: SyncMutation?
        store.onSyncMutation = { if $0.kind == .favorite { m = $0 } }
        store.toggleFavorite(e)
        #expect(m?.kind == .favorite)
        #expect(m?.deleted == false)
    }
    @Test func applyCloudFavoriteUpsertInsertsNoEcho() {
        let store = freshStore()
        var echoed = false; store.onSyncMutation = { _ in echoed = true }
        let e = FoodEntry(name: "CloudFav", calories: 10, protein: 0, carbs: 0, fat: 0, source: .manual)
        store.applyCloudFavoriteUpsert(e)
        #expect(store.favorites.contains { $0.id == e.id }); #expect(echoed == false)
    }
}
```

- [ ] **Step 2: Run to verify it fails** — Expected: FAIL.

- [ ] **Step 3: Implement**

In the favorite add path (`toggleFavorite` / `addFavorite` — whichever calls `saveFavorites()` to add), after persisting emit `onSyncMutation?(SyncMutation(kind: .favorite, id: favorite.id, deleted: false))`; in the remove path emit `deleted: true`. Add inbound:

```swift
func applyCloudFavoriteUpsert(_ incoming: FoodEntry) {
    if let idx = favorites.firstIndex(where: { $0.id == incoming.id }) {
        guard incoming.effectiveModifiedAt >= favorites[idx].effectiveModifiedAt else { return }
        favorites[idx] = incoming
    } else {
        favorites.append(incoming)
    }
    saveFavorites()
}
func applyCloudFavoriteDelete(id: UUID) {
    favorites.removeAll { $0.id == id }
    saveFavorites()
}
```

> Read the current favorite add/remove method names in `FoodStore.swift` (around lines 225–255) and place the emits at those exact sites. `saveFavorites()` is `private` and stays so.

- [ ] **Step 4: Run to verify it passes** — Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: FoodStore favorites sync hook + LWW inbound apply"
```

---

## Phase 3 — Record mapping incl. `CKAsset` (TDD)

`CKRecord` is an in-memory object; mapping is unit-testable without an iCloud account. Photos need a file URL, so first expose one from the image stores.

### Task 3.1: Expose `fileURL(for:)` on the image stores

**Files:**
- Modify: `ios/calorietracker/Services/FoodImageStore.swift`
- Modify: `ios/calorietracker/Services/WeightPhotoStore.swift`
- Test: `ios/calorietrackerTests/ImageStoreURLTests.swift` (create)

- [ ] **Step 1: Write the failing test**

```swift
import Testing
import Foundation
@testable import calorietracker

struct ImageStoreURLTests {
    @Test func foodImageURLRoundTrips() throws {
        let id = UUID()
        let bytes = Data([0xFF, 0xD8, 0xFF, 0xD9])
        let name = try #require(FoodImageStore.shared.store(data: bytes, for: id))
        let url = try #require(FoodImageStore.shared.fileURL(for: name))
        #expect(FileManager.default.fileExists(atPath: url.path))
        FoodImageStore.shared.delete(filename: name)
    }
    @Test func missingFileURLIsNil() {
        // fileURL returns nil only if the container can't be resolved; for a
        // never-written name it still returns a URL (the file just won't exist).
        let url = FoodImageStore.shared.fileURL(for: "does-not-exist.jpg")
        if let url { #expect(!FileManager.default.fileExists(atPath: url.path)) }
    }
}
```

- [ ] **Step 2: Run to verify it fails** — Expected: FAIL (no member `fileURL`).

- [ ] **Step 3: Implement** — add to BOTH `FoodImageStore` and `WeightPhotoStore`:

```swift
/// Full file URL for a stored filename, or nil if the container is unavailable.
/// The file may not exist yet — callers should check before reading.
func fileURL(for filename: String) -> URL? {
    guard let folderURL else { return nil }
    return folderURL.appendingPathComponent(filename)
}
```

- [ ] **Step 4: Run to verify it passes** — Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: expose fileURL(for:) on FoodImageStore + WeightPhotoStore for CKAsset"
```

### Task 3.2: `FoodRecordMapper` — model ↔ CKRecord with modifiedAt + CKAsset

**Files:**
- Create: `ios/calorietracker/Services/Sync/FoodRecordMapper.swift`
- Test: `ios/calorietrackerTests/FoodRecordMapperTests.swift` (create)

- [ ] **Step 1: Write the failing test**

```swift
import Testing
import Foundation
import CloudKit
@testable import calorietracker

struct FoodRecordMapperTests {
    private let zoneID = CKRecordZone.ID(zoneName: "VoidpenZone", ownerName: CKCurrentUserDefaultName)

    @Test func roundTripCoreFields() throws {
        let stamp = Date(timeIntervalSince1970: 1_700_000_000)
        let e = FoodEntry(name: "Steak", calories: 500, protein: 40, carbs: 0, fat: 35,
                          source: .manual, mealType: .dinner, sugar: 1.5, sodium: 90, modifiedAt: stamp)
        let rec = FoodRecordMapper.record(from: e, kind: .food, zoneID: zoneID)
        #expect(rec.recordID.recordName == "food_\(e.id.uuidString)")
        #expect(rec.recordType == "FoodEntry")
        let back = try #require(FoodRecordMapper.foodEntry(from: rec))
        #expect(back.id == e.id)
        #expect(back.name == "Steak")
        #expect(back.calories == 500)
        #expect(back.sugar == 1.5)
        #expect(back.sodium == 90)
        #expect(back.mealType == .dinner)
        #expect(back.modifiedAt == stamp)
    }

    @Test func favoriteUsesFavPrefixAndType() {
        let e = FoodEntry(name: "F", calories: 1, protein: 0, carbs: 0, fat: 0, source: .manual)
        let rec = FoodRecordMapper.record(from: e, kind: .favorite, zoneID: zoneID)
        #expect(rec.recordID.recordName == "fav_\(e.id.uuidString)")
        #expect(rec.recordType == "FoodFavorite")
    }

    @Test func photoBecomesAssetAndDecodesBack() throws {
        let id = UUID()
        let jpeg = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0xFF, 0xD9])
        let filename = try #require(FoodImageStore.shared.store(data: jpeg, for: id))
        let e = FoodEntry(id: id, name: "WithPhoto", calories: 1, protein: 0, carbs: 0, fat: 0,
                          imageFilename: filename, source: .manual)
        let rec = FoodRecordMapper.record(from: e, kind: .food, zoneID: zoneID)
        #expect(rec["photo"] as? CKAsset != nil)
        // Simulate inbound: decode writes the asset bytes back to the image store.
        FoodImageStore.shared.delete(filename: filename)
        let back = try #require(FoodRecordMapper.foodEntry(from: rec))
        #expect(back.imageFilename == filename)
        #expect(FoodImageStore.shared.load(filename: filename) == jpeg)
        FoodImageStore.shared.delete(filename: filename)
    }
}
```

- [ ] **Step 2: Run to verify it fails** — Expected: FAIL (no type `FoodRecordMapper`).

- [ ] **Step 3: Implement**

```swift
import Foundation
import CloudKit

/// Maps FoodEntry ↔ CKRecord (used for both logged entries and favorites).
/// Photos travel as CKAsset; decode writes the bytes back to FoodImageStore.
enum FoodRecordMapper {

    static func record(from entry: FoodEntry, kind: SyncRecordKind, zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: kind.recordName(for: entry.id), zoneID: zoneID)
        let record = CKRecord(recordType: kind.recordType, recordID: recordID)
        record["entryID"] = entry.id.uuidString
        record["name"] = entry.name
        record["calories"] = entry.calories
        record["protein"] = entry.protein
        record["carbs"] = entry.carbs
        record["fat"] = entry.fat
        record["timestamp"] = entry.timestamp
        record["emoji"] = entry.emoji
        record["source"] = entry.source.rawValue
        record["mealType"] = entry.mealType.rawValue
        record["modifiedAt"] = entry.modifiedAt
        for (key, value) in [
            "sugar": entry.sugar, "addedSugar": entry.addedSugar, "fiber": entry.fiber,
            "saturatedFat": entry.saturatedFat, "monounsaturatedFat": entry.monounsaturatedFat,
            "polyunsaturatedFat": entry.polyunsaturatedFat, "cholesterol": entry.cholesterol,
            "sodium": entry.sodium, "potassium": entry.potassium, "servingSizeGrams": entry.servingSizeGrams,
        ] {
            if let value { record[key] = value }
        }
        if let filename = entry.imageFilename,
           let url = FoodImageStore.shared.fileURL(for: filename),
           FileManager.default.fileExists(atPath: url.path) {
            record["photoFilename"] = filename
            record["photo"] = CKAsset(fileURL: url)
        }
        return record
    }

    static func foodEntry(from record: CKRecord) -> FoodEntry? {
        guard let idString = record["entryID"] as? String, let id = UUID(uuidString: idString),
              let name = record["name"] as? String,
              let calories = record["calories"] as? Int,
              let protein = record["protein"] as? Int,
              let carbs = record["carbs"] as? Int,
              let fat = record["fat"] as? Int,
              let timestamp = record["timestamp"] as? Date,
              let sourceRaw = record["source"] as? String,
              let source = FoodSource(rawValue: sourceRaw)
        else { return nil }

        // Materialize the photo back to local disk under its logical filename.
        // Keep the filename regardless; write bytes back only if the asset is present.
        let imageFilename = record["photoFilename"] as? String
        if imageFilename != nil, let asset = record["photo"] as? CKAsset, let url = asset.fileURL,
           let data = try? Data(contentsOf: url) {
            _ = FoodImageStore.shared.store(data: data, for: id)
        }

        let mealType = MealType(rawValue: record["mealType"] as? String ?? "") ?? .other
        return FoodEntry(
            id: id, name: name, calories: calories, protein: protein, carbs: carbs, fat: fat,
            timestamp: timestamp, imageData: nil, imageFilename: imageFilename,
            emoji: record["emoji"] as? String, source: source, mealType: mealType,
            sugar: record["sugar"] as? Double, addedSugar: record["addedSugar"] as? Double,
            fiber: record["fiber"] as? Double, saturatedFat: record["saturatedFat"] as? Double,
            monounsaturatedFat: record["monounsaturatedFat"] as? Double,
            polyunsaturatedFat: record["polyunsaturatedFat"] as? Double,
            cholesterol: record["cholesterol"] as? Double, sodium: record["sodium"] as? Double,
            potassium: record["potassium"] as? Double, servingSizeGrams: record["servingSizeGrams"] as? Double,
            modifiedAt: record["modifiedAt"] as? Date
        )
    }
}
```

> `FoodImageStore.store(data:for:)` derives the filename as `<uuid>.jpg`, matching the original `imageFilename`, so writing the asset bytes back restores the exact same filename the entry references.

- [ ] **Step 4: Run to verify it passes** — Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: FoodRecordMapper with modifiedAt + CKAsset photo round-trip"
```

### Task 3.3: `WeightRecordMapper` (with photo asset)

**Files:**
- Create: `ios/calorietracker/Services/Sync/WeightRecordMapper.swift`
- Test: `ios/calorietrackerTests/WeightRecordMapperTests.swift` (create)

- [ ] **Step 1: Write the failing test**

```swift
import Testing
import Foundation
import CloudKit
@testable import calorietracker

struct WeightRecordMapperTests {
    private let zoneID = CKRecordZone.ID(zoneName: "VoidpenZone", ownerName: CKCurrentUserDefaultName)
    @Test func roundTrip() throws {
        let stamp = Date(timeIntervalSince1970: 1_700_000_000)
        let e = WeightEntry(date: Date(timeIntervalSince1970: 1000), weightKg: 73.2, modifiedAt: stamp)
        let rec = WeightRecordMapper.record(from: e, zoneID: zoneID)
        #expect(rec.recordType == "WeightEntry")
        #expect(rec.recordID.recordName == "weight_\(e.id.uuidString)")
        let back = try #require(WeightRecordMapper.weightEntry(from: rec))
        #expect(back.id == e.id); #expect(back.weightKg == 73.2); #expect(back.modifiedAt == stamp)
    }
}
```

- [ ] **Step 2: Run to verify it fails** — Expected: FAIL.

- [ ] **Step 3: Implement**

```swift
import Foundation
import CloudKit

enum WeightRecordMapper {
    static func record(from entry: WeightEntry, zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: SyncRecordKind.weight.recordName(for: entry.id), zoneID: zoneID)
        let record = CKRecord(recordType: SyncRecordKind.weight.recordType, recordID: recordID)
        record["entryID"] = entry.id.uuidString
        record["date"] = entry.date
        record["weightKg"] = entry.weightKg
        record["modifiedAt"] = entry.modifiedAt
        if let filename = entry.photoFilename,
           let url = WeightPhotoStore.shared.fileURL(for: filename),
           FileManager.default.fileExists(atPath: url.path) {
            record["photoFilename"] = filename
            record["photo"] = CKAsset(fileURL: url)
        }
        return record
    }
    static func weightEntry(from record: CKRecord) -> WeightEntry? {
        guard let idString = record["entryID"] as? String, let id = UUID(uuidString: idString),
              let date = record["date"] as? Date, let weightKg = record["weightKg"] as? Double
        else { return nil }
        var photoFilename = record["photoFilename"] as? String
        if let photoFilename, let asset = record["photo"] as? CKAsset, let url = asset.fileURL,
           let data = try? Data(contentsOf: url) {
            _ = WeightPhotoStore.shared.store(data: data, for: id)
        }
        return WeightEntry(id: id, date: date, weightKg: weightKg, photoFilename: photoFilename,
                           modifiedAt: record["modifiedAt"] as? Date)
    }
}
```

- [ ] **Step 4: Run to verify it passes** — Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: WeightRecordMapper with modifiedAt + CKAsset photo"
```

### Task 3.4: `BodyFatRecordMapper`

**Files:**
- Create: `ios/calorietracker/Services/Sync/BodyFatRecordMapper.swift`
- Test: `ios/calorietrackerTests/BodyFatRecordMapperTests.swift` (create)

- [ ] **Step 1: Write the failing test**

```swift
import Testing
import Foundation
import CloudKit
@testable import calorietracker

struct BodyFatRecordMapperTests {
    private let zoneID = CKRecordZone.ID(zoneName: "VoidpenZone", ownerName: CKCurrentUserDefaultName)
    @Test func roundTrip() throws {
        let e = BodyFatEntry(date: Date(timeIntervalSince1970: 500), bodyFatFraction: 0.21,
                             modifiedAt: Date(timeIntervalSince1970: 1_700_000_000))
        let rec = BodyFatRecordMapper.record(from: e, zoneID: zoneID)
        #expect(rec.recordType == "BodyFatEntry")
        let back = try #require(BodyFatRecordMapper.bodyFatEntry(from: rec))
        #expect(back.id == e.id); #expect(back.bodyFatFraction == 0.21)
    }
}
```

- [ ] **Step 2: Run to verify it fails** — Expected: FAIL.

- [ ] **Step 3: Implement** (no photos):

```swift
import Foundation
import CloudKit

enum BodyFatRecordMapper {
    static func record(from entry: BodyFatEntry, zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: SyncRecordKind.bodyFat.recordName(for: entry.id), zoneID: zoneID)
        let record = CKRecord(recordType: SyncRecordKind.bodyFat.recordType, recordID: recordID)
        record["entryID"] = entry.id.uuidString
        record["date"] = entry.date
        record["bodyFatFraction"] = entry.bodyFatFraction
        record["modifiedAt"] = entry.modifiedAt
        return record
    }
    static func bodyFatEntry(from record: CKRecord) -> BodyFatEntry? {
        guard let idString = record["entryID"] as? String, let id = UUID(uuidString: idString),
              let date = record["date"] as? Date, let fraction = record["bodyFatFraction"] as? Double
        else { return nil }
        return BodyFatEntry(id: id, date: date, bodyFatFraction: fraction, modifiedAt: record["modifiedAt"] as? Date)
    }
}
```

- [ ] **Step 4: Run to verify it passes** — Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: BodyFatRecordMapper"
```

### Task 3.5: `ChatRecordMapper` (messages as JSON blob)

**Files:**
- Create: `ios/calorietracker/Services/Sync/ChatRecordMapper.swift`
- Test: `ios/calorietrackerTests/ChatRecordMapperTests.swift` (create)

- [ ] **Step 1: Write the failing test**

```swift
import Testing
import Foundation
import CloudKit
@testable import calorietracker

struct ChatRecordMapperTests {
    private let zoneID = CKRecordZone.ID(zoneName: "VoidpenZone", ownerName: CKCurrentUserDefaultName)
    @Test func roundTrip() throws {
        let t = ChatThread(title: "Diet Qs",
                           messages: [ChatMessage(role: .user, content: "hi"),
                                      ChatMessage(role: .assistant, content: "hello")],
                           createdAt: Date(timeIntervalSince1970: 1), updatedAt: Date(timeIntervalSince1970: 2))
        let rec = ChatRecordMapper.record(from: t, zoneID: zoneID)
        #expect(rec.recordType == "ChatThread")
        #expect(rec.recordID.recordName == "chat_\(t.id.uuidString)")
        let back = try #require(ChatRecordMapper.chatThread(from: rec))
        #expect(back.id == t.id); #expect(back.title == "Diet Qs")
        #expect(back.messages.count == 2); #expect(back.messages.last?.content == "hello")
        #expect(back.updatedAt == t.updatedAt)
    }
}
```

- [ ] **Step 2: Run to verify it fails** — Expected: FAIL.

- [ ] **Step 3: Implement** (encode the full thread as JSON; `updatedAt` is the LWW key, surfaced as `modifiedAt` too):

```swift
import Foundation
import CloudKit

enum ChatRecordMapper {
    static func record(from thread: ChatThread, zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: SyncRecordKind.chat.recordName(for: thread.id), zoneID: zoneID)
        let record = CKRecord(recordType: SyncRecordKind.chat.recordType, recordID: recordID)
        record["threadID"] = thread.id.uuidString
        record["updatedAt"] = thread.updatedAt
        record["payload"] = (try? JSONEncoder().encode(thread)).map { String(decoding: $0, as: UTF8.self) }
        return record
    }
    static func chatThread(from record: CKRecord) -> ChatThread? {
        guard let payload = record["payload"] as? String,
              let data = payload.data(using: .utf8),
              let thread = try? JSONDecoder().decode(ChatThread.self, from: data)
        else { return nil }
        return thread
    }
}
```

> `ChatMessage` is already `Codable` (it's persisted inside `ChatThread`), so encoding the whole thread is the simplest faithful representation. If a `ChatMessage` carries `attachmentImageData`, that rides inside the JSON blob — acceptable for chat (small) and keeps fidelity.

- [ ] **Step 4: Run to verify it passes** — Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: ChatRecordMapper (thread payload as JSON)"
```

### Task 3.6: `ProfileRecordMapper` (singleton)

**Files:**
- Create: `ios/calorietracker/Services/Sync/ProfileRecordMapper.swift`
- Test: `ios/calorietrackerTests/ProfileRecordMapperTests.swift` (create)

- [ ] **Step 1: Write the failing test**

```swift
import Testing
import Foundation
import CloudKit
@testable import calorietracker

struct ProfileRecordMapperTests {
    private let zoneID = CKRecordZone.ID(zoneName: "VoidpenZone", ownerName: CKCurrentUserDefaultName)
    @Test func roundTrip() throws {
        var p = UserProfile.default
        p.weightKg = 78
        p.modifiedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let rec = ProfileRecordMapper.record(from: p, zoneID: zoneID)
        #expect(rec.recordType == "UserProfile")
        #expect(rec.recordID.recordName == "profile")
        let back = try #require(ProfileRecordMapper.profile(from: rec))
        #expect(back.weightKg == 78); #expect(back.modifiedAt == p.modifiedAt)
    }
}
```

- [ ] **Step 2: Run to verify it fails** — Expected: FAIL.

- [ ] **Step 3: Implement** (encode the whole profile as a JSON blob — robust to UserProfile gaining fields, and it already bundles `OptionalNutrientGoals`-style customs):

```swift
import Foundation
import CloudKit

enum ProfileRecordMapper {
    static func record(from profile: UserProfile, zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(recordName: SyncRecordKind.profile.fixedRecordName, zoneID: zoneID)
        let record = CKRecord(recordType: SyncRecordKind.profile.recordType, recordID: recordID)
        record["modifiedAt"] = profile.modifiedAt
        record["payload"] = (try? JSONEncoder().encode(profile)).map { String(decoding: $0, as: UTF8.self) }
        return record
    }
    static func profile(from record: CKRecord) -> UserProfile? {
        guard let payload = record["payload"] as? String,
              let data = payload.data(using: .utf8),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data)
        else { return nil }
        return profile
    }
}
```

> Bundling `OptionalNutrientGoals` (stored separately under `optionalNutrientGoals`): the spec folds goals into the profile record. Since `OptionalNutrientGoals` is a separate UserDefaults blob, add it as a second field on this record: `record["optionalGoals"] = (try? JSONEncoder().encode(OptionalNutrientGoals.load())).map { String(decoding: $0, as: UTF8.self) }` and on decode call the goals' `save`-equivalent. **Read `OptionalNutrientGoals.swift` first** to use its real load/save API; if its surface is awkward, ship profile-only in v1 and file goals-sync as a follow-up (note it in the PR).

- [ ] **Step 4: Run to verify it passes** — Expected: PASS.

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: ProfileRecordMapper (singleton, JSON payload)"
```

---

## Phase 4 — Capability & project setup (manual + edits)

These can't be unit-tested; verify by building and by the manual checklist in Phase 7.

### Task 4.1: Enable the CloudKit container in entitlements

**Files:**
- Modify: `ios/calorietracker/calorietracker.entitlements`

- [ ] **Step 1: Fill in the (currently empty) iCloud keys**

Replace the empty arrays:
```xml
<key>com.apple.developer.icloud-container-identifiers</key>
<array>
    <string>iCloud.com.cotrinhhienduy.calorietracker</string>
</array>
<key>com.apple.developer.icloud-services</key>
<array>
    <string>CloudKit</string>
</array>
```
Leave `aps-environment`, `applesignin`, healthkit, and app-groups untouched.

- [ ] **Step 2: Add the background mode for silent-push sync**

In the app target's Info settings (project → target → Info, or the Info.plist if present), add `UIBackgroundModes` containing `remote-notification`. If editing Info.plist directly:
```xml
<key>UIBackgroundModes</key>
<array>
    <string>remote-notification</string>
</array>
```

- [ ] **Step 3: Enable the capability in the Apple Developer portal (MANUAL — Dan)**

In Xcode: target → Signing & Capabilities → **+ Capability → iCloud → check CloudKit → select container `iCloud.com.cotrinhhienduy.calorietracker`** (create it if it doesn't exist). This updates the provisioning profile. *Agent cannot do this — flag for Dan.*

- [ ] **Step 4: Build to confirm entitlements parse**

Run: `cd ios && xcodebuild build -scheme calorietracker -destination 'platform=iOS Simulator,name=iPhone 16' -quiet`
Expected: BUILD SUCCEEDED (signing may warn on simulator; that's fine).

- [ ] **Step 5: Commit**

```bash
git add -A && git commit -m "feat: enable CloudKit container + remote-notification background mode"
```

---

## Phase 5 — `CloudSyncCoordinator` (CKSyncEngine) — implementation + device verify

Not unit-testable without an iCloud account; verified on device in Phase 7. **Before starting, fetch current `CKSyncEngine` docs via context7 and confirm the API.**

### Task 5.1: Adapter registry that routes records to stores

**Files:**
- Create: `ios/calorietracker/Services/Sync/SyncStores.swift`

- [ ] **Step 1: Implement a value holding references to the live stores**

```swift
import Foundation

/// Bundles the live store instances the coordinator reads from / writes to.
@MainActor
struct SyncStores {
    let food: FoodStore
    let weight: WeightStore
    let bodyFat: BodyFatStore
    let chat: ChatStore
    // Profile is a singleton persisted via UserProfile.load()/save(); no store ref needed.
}
```

- [ ] **Step 2: Build** — Run the build command. Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat: SyncStores bundle for the sync coordinator"
```

### Task 5.2: The coordinator

**Files:**
- Create: `ios/calorietracker/Services/Sync/CloudSyncCoordinator.swift`

- [ ] **Step 1: Implement** (verify enum case names against the SDK as noted above)

```swift
import Foundation
import CloudKit
import os

/// Observable sync status surfaced in Settings.
enum CloudSyncStatus: Equatable {
    case idle
    case syncing
    case upToDate(Date?)
    case unavailable
    case error(String)
}

/// Owns the CKSyncEngine, routes local mutations out and remote changes in.
@MainActor
@Observable
final class CloudSyncCoordinator {
    static let containerID = "iCloud.com.cotrinhhienduy.calorietracker"
    static let zoneName = "VoidpenZone"
    private static let stateKey = "ckSyncEngineState"
    private static let lastSyncKey = "ckSyncLastSuccess"

    private(set) var status: CloudSyncStatus = .idle

    private let stores: SyncStores
    private let container: CKContainer
    private let zoneID: CKRecordZone.ID
    private var engine: CKSyncEngine?
    private let log = Logger(subsystem: "com.cotrinhhienduy.calorietracker", category: "sync")

    init(stores: SyncStores) {
        self.stores = stores
        self.container = CKContainer(identifier: Self.containerID)
        self.zoneID = CKRecordZone.ID(zoneName: Self.zoneName, ownerName: CKCurrentUserDefaultName)
    }

    /// Build the engine and kick an initial sync. Safe to call once after launch.
    func start() {
        guard engine == nil else { return }
        var config = CKSyncEngine.Configuration(
            database: container.privateCloudDatabase,
            stateSerialization: loadState(),
            delegate: self
        )
        config.automaticallySync = true
        self.engine = CKSyncEngine(config)
        status = .syncing
        // Ensure the zone exists, then push any local rows the engine doesn't know yet.
        Task { await self.pushAllLocalIfFreshZone() }
    }

    /// Called by stores on user-driven mutations.
    func record(_ mutation: SyncMutation) {
        guard let engine else { return }
        let recordID = CKRecord.ID(recordName: mutation.kind.recordName(for: mutation.id), zoneID: zoneID)
        let change: CKSyncEngine.PendingRecordZoneChange = mutation.deleted ? .deleteRecord(recordID) : .saveRecord(recordID)
        engine.state.add(pendingRecordZoneChanges: [change])
    }

    /// Push the profile singleton (call after profile edits — profile has no store hook).
    func recordProfileChange() {
        guard let engine else { return }
        let recordID = CKRecord.ID(recordName: SyncRecordKind.profile.fixedRecordName, zoneID: zoneID)
        engine.state.add(pendingRecordZoneChanges: [.saveRecord(recordID)])
    }

    // MARK: - State persistence

    private func loadState() -> CKSyncEngine.State.Serialization? {
        guard let data = UserDefaults.standard.data(forKey: Self.stateKey) else { return nil }
        return try? JSONDecoder().decode(CKSyncEngine.State.Serialization.self, from: data)
    }
    private func saveState(_ serialization: CKSyncEngine.State.Serialization) {
        if let data = try? JSONEncoder().encode(serialization) {
            UserDefaults.standard.set(data, forKey: Self.stateKey)
        }
    }

    private func pushAllLocalIfFreshZone() async {
        // On a brand-new install/account the engine has no record of local rows.
        // Enqueue them all as saves; the engine dedupes against server state.
        guard let engine else { return }
        var changes: [CKSyncEngine.PendingRecordZoneChange] = []
        for e in stores.food.entries { changes.append(.saveRecord(id(.food, e.id))) }
        for f in stores.food.favorites { changes.append(.saveRecord(id(.favorite, f.id))) }
        for w in stores.weight.entries { changes.append(.saveRecord(id(.weight, w.id))) }
        for b in stores.bodyFat.entries { changes.append(.saveRecord(id(.bodyFat, b.id))) }
        for t in stores.chat.threads { changes.append(.saveRecord(id(.chat, t.id))) }
        changes.append(.saveRecord(CKRecord.ID(recordName: SyncRecordKind.profile.fixedRecordName, zoneID: zoneID)))
        engine.state.add(pendingRecordZoneChanges: changes)
    }

    private func id(_ kind: SyncRecordKind, _ uuid: UUID) -> CKRecord.ID {
        CKRecord.ID(recordName: kind.recordName(for: uuid), zoneID: zoneID)
    }
}
```

- [ ] **Step 2: Build** — Expected: BUILD SUCCEEDED (delegate conformance added next; if the compiler complains about missing protocol methods, proceed to Step 3 before building).

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat: CloudSyncCoordinator skeleton (engine, state, outbound enqueue)"
```

### Task 5.3: `CKSyncEngineDelegate` — batch building + event handling

**Files:**
- Create: `ios/calorietracker/Services/Sync/CloudSyncCoordinator+Delegate.swift`

- [ ] **Step 1: Implement the delegate**

```swift
import Foundation
import CloudKit

extension CloudSyncCoordinator: CKSyncEngineDelegate {

    /// Build the next batch of records to send from CURRENT local state.
    func nextRecordZoneChangeBatch(
        _ context: CKSyncEngine.SendChangesContext,
        syncEngine: CKSyncEngine
    ) async -> CKSyncEngine.RecordZoneChangeBatch? {
        let pending = syncEngine.state.pendingRecordZoneChanges.filter {
            if case .saveRecord = $0 { return true } else { return false }
        }
        guard !pending.isEmpty else { return nil }
        return await CKSyncEngine.RecordZoneChangeBatch(pendingChanges: pending) { recordID in
            await self.materialize(recordID: recordID)
        }
    }

    /// Turn a recordID into a fresh CKRecord from local state, or nil to drop it.
    private func materialize(recordID: CKRecord.ID) async -> CKRecord? {
        let name = recordID.recordName
        if name == SyncRecordKind.profile.fixedRecordName {
            guard let profile = UserProfile.load() else { return nil }
            return ProfileRecordMapper.record(from: profile, zoneID: zoneID)
        }
        guard let (kind, uuid) = SyncRecordKind.parse(recordName: name) else { return nil }
        switch kind {
        case .food:
            guard let e = stores.food.entries.first(where: { $0.id == uuid }) else { return nil }
            return FoodRecordMapper.record(from: e, kind: .food, zoneID: zoneID)
        case .favorite:
            guard let f = stores.food.favorites.first(where: { $0.id == uuid }) else { return nil }
            return FoodRecordMapper.record(from: f, kind: .favorite, zoneID: zoneID)
        case .weight:
            guard let w = stores.weight.entries.first(where: { $0.id == uuid }) else { return nil }
            return WeightRecordMapper.record(from: w, zoneID: zoneID)
        case .bodyFat:
            guard let b = stores.bodyFat.entries.first(where: { $0.id == uuid }) else { return nil }
            return BodyFatRecordMapper.record(from: b, zoneID: zoneID)
        case .chat:
            guard let t = stores.chat.threads.first(where: { $0.id == uuid }) else { return nil }
            return ChatRecordMapper.record(from: t, zoneID: zoneID)
        case .profile:
            return nil
        }
    }

    func handleEvent(_ event: CKSyncEngine.Event, syncEngine: CKSyncEngine) async {
        switch event {
        case .stateUpdate(let e):
            saveState(e.stateSerialization)

        case .accountChange(let e):
            await handleAccountChange(e)

        case .fetchedRecordZoneChanges(let e):
            for mod in e.modifications { applyIncoming(mod.record) }
            for del in e.deletions { applyIncomingDelete(recordName: del.recordID.recordName) }

        case .sentRecordZoneChanges(let e):
            for failed in e.failedRecordSaves {
                handleSendFailure(record: failed.record, error: failed.error, syncEngine: syncEngine)
            }

        case .willFetchChanges, .willSendChanges:
            status = .syncing
        case .didSendChanges, .didFetchChanges:
            let now = Date()
            UserDefaults.standard.set(now, forKey: Self.lastSyncKey)
            status = .upToDate(now)

        @unknown default:
            break
        }
    }

    private func applyIncoming(_ record: CKRecord) {
        switch SyncRecordKind.kind(forRecordType: record.recordType) {
        case .food:     if let e = FoodRecordMapper.foodEntry(from: record) { stores.food.applyCloudUpsert(e) }
        case .favorite: if let f = FoodRecordMapper.foodEntry(from: record) { stores.food.applyCloudFavoriteUpsert(f) }
        case .weight:   if let w = WeightRecordMapper.weightEntry(from: record) { stores.weight.applyCloudUpsert(w) }
        case .bodyFat:  if let b = BodyFatRecordMapper.bodyFatEntry(from: record) { stores.bodyFat.applyCloudUpsert(b) }
        case .chat:     if let t = ChatRecordMapper.chatThread(from: record) { stores.chat.applyCloudUpsert(t) }
        case .profile:  applyIncomingProfile(record)
        case .none:     break
        }
    }

    private func applyIncomingProfile(_ record: CKRecord) {
        guard let incoming = ProfileRecordMapper.profile(from: record) else { return }
        let localStamp = UserProfile.load()?.effectiveModifiedAt ?? .distantPast
        guard incoming.effectiveModifiedAt >= localStamp else { return }
        incoming.savePreservingTimestamp()  // no echo: profile push is explicit via recordProfileChange()
    }

    private func applyIncomingDelete(recordName: String) {
        if recordName == SyncRecordKind.profile.fixedRecordName { return } // never delete the profile
        guard let (kind, uuid) = SyncRecordKind.parse(recordName: recordName) else { return }
        switch kind {
        case .food:     stores.food.applyCloudDelete(id: uuid)
        case .favorite: stores.food.applyCloudFavoriteDelete(id: uuid)
        case .weight:   stores.weight.applyCloudDelete(id: uuid)
        case .bodyFat:  stores.bodyFat.applyCloudDelete(id: uuid)
        case .chat:     stores.chat.applyCloudDelete(id: uuid)
        case .profile:  break
        }
    }

    private func handleSendFailure(record: CKRecord, error: CKError, syncEngine: CKSyncEngine) {
        switch error.code {
        case .serverRecordChanged:
            // Conflict: server has a newer/different copy. LWW — re-enqueue our
            // local save only if our modifiedAt is newer than the server record's.
            if let serverRecord = error.serverRecord,
               let serverStamp = serverRecord["modifiedAt"] as? Date,
               let localStamp = record["modifiedAt"] as? Date,
               localStamp <= serverStamp {
                applyIncoming(serverRecord)  // accept server copy
            } else {
                syncEngine.state.add(pendingRecordZoneChanges: [.saveRecord(record.recordID)])
            }
        case .zoneNotFound, .userDeletedZone:
            // Recreate the zone and push everything again.
            syncEngine.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: zoneID))])
            Task { await pushAllLocalIfFreshZone() }
        case .notAuthenticated, .accountTemporarilyUnavailable:
            status = .unavailable
        case .quotaExceeded:
            status = .error("iCloud storage full")
        default:
            break
        }
    }

    private func handleAccountChange(_ e: CKSyncEngine.Event.AccountChange) async {
        switch e.changeType {
        case .signIn:
            await pushAllLocalIfFreshZone()
        case .switchAccounts, .signOut:
            // Keep local data; drop sync state so we don't push one user's data to another.
            UserDefaults.standard.removeObject(forKey: Self.stateKey)
            status = .unavailable
        @unknown default:
            break
        }
    }
}
```

- [ ] **Step 2: Build** — Run the build command. Expected: BUILD SUCCEEDED. Fix any SDK signature mismatches surfaced by the compiler (this is where API drift shows up — consult the context7 docs).

- [ ] **Step 3: Commit**

```bash
git add -A && git commit -m "feat: CKSyncEngine delegate — batch building + inbound apply + conflict/account handling"
```

### Task 5.4: Wire the coordinator into the app

**Files:**
- Modify: `ios/calorietracker/calorietrackerApp.swift`

- [ ] **Step 1: Add the coordinator as app state and start it**

1. Add a stored property: `@State private var syncCoordinator: CloudSyncCoordinator?`
2. Add a method that builds + wires it (call from `wireUpAppDataCallbacks()` so it runs once onboarding is complete):

```swift
private func wireUpCloudSync() {
    guard hasCompletedOnboarding, syncCoordinator == nil else { return }
    let coordinator = CloudSyncCoordinator(
        stores: SyncStores(food: foodStore, weight: weightStore, bodyFat: bodyFatStore, chat: chatStore)
    )
    foodStore.onSyncMutation = { coordinator.record($0) }
    weightStore.onSyncMutation = { coordinator.record($0) }
    bodyFatStore.onSyncMutation = { coordinator.record($0) }
    chatStore.onSyncMutation = { coordinator.record($0) }
    syncCoordinator = coordinator
    coordinator.start()
}
```

3. In `wireUpAppDataCallbacks()`, add `wireUpCloudSync()` after `wireUpHealthKit()`.
4. Push profile edits: add an `.onReceive(NotificationCenter.default.publisher(for: .userProfileDidChange))` handler (the app already has one for the widget) that calls `syncCoordinator?.recordProfileChange()`. **Guard against echo:** `applyIncomingProfile` uses `savePreservingTimestamp()` which also posts `.userProfileDidChange`; to avoid a re-push loop, only enqueue when the change originated locally. Simplest: in `recordProfileChange()`, the engine already dedupes identical records, and LWW makes a redundant push harmless — accept the occasional no-op push. (If churn shows in testing, add a `suppressNextProfilePush` flag set before `savePreservingTimestamp()`.)

- [ ] **Step 2: Build** — Expected: BUILD SUCCEEDED.

- [ ] **Step 3: Run the app in the simulator (signed into an iCloud account)**

Run: `cd ios && xcodebuild build -scheme calorietracker -destination 'platform=iOS Simulator,name=iPhone 16' -quiet` then launch via Xcode or `xcrun simctl`.
Expected: app launches, no crash; Console shows the `sync` logger initializing the engine.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat: wire CloudSyncCoordinator into app lifecycle + store hooks"
```

---

## Phase 6 — Settings status row (UI)

### Task 6.1: Read-only iCloud sync status row

**Files:**
- Create: `ios/calorietracker/Views/CloudSyncStatusRow.swift`
- Modify: the Settings view that lists rows (find it: `grep -rn "Settings" ios/calorietracker/Views | grep -i view`)

- [ ] **Step 1: Implement the row**

```swift
import SwiftUI

struct CloudSyncStatusRow: View {
    let status: CloudSyncStatus

    var body: some View {
        HStack {
            Label("iCloud Sync", systemImage: "icloud")
            Spacer()
            Text(detail).foregroundStyle(.secondary).font(.subheadline)
        }
    }

    private var detail: String {
        switch status {
        case .idle, .syncing: return "Syncing…"
        case .upToDate(let date):
            guard let date else { return "Up to date" }
            let f = RelativeDateTimeFormatter(); f.unitsStyle = .short
            return f.localizedString(for: date, relativeTo: Date())
        case .unavailable: return "iCloud unavailable"
        case .error(let msg): return msg
        }
    }
}
```

- [ ] **Step 2: Insert into Settings**

Add to the settings list (where the coordinator is in scope via `@Environment` or passed in):
```swift
if let coordinator = syncCoordinator {
    CloudSyncStatusRow(status: coordinator.status)
}
```
> If Settings can't see `syncCoordinator`, pass the coordinator into the environment in `calorietrackerApp.swift` (`.environment(coordinator)`) once it's non-nil, and read it with `@Environment(CloudSyncCoordinator.self)`.

- [ ] **Step 3: Build** — Expected: BUILD SUCCEEDED.

- [ ] **Step 4: Commit**

```bash
git add -A && git commit -m "feat: iCloud sync status row in Settings"
```

---

## Phase 7 — Manual verification & CloudKit production deploy

No code; this is the gate before release. Record results in the PR.

### Task 7.1: CloudKit Dashboard — schema in Development

- [ ] Run the app once on a real device signed into iCloud, then add one entry of each kind (food w/ photo, weight w/ photo, body fat, chat thread, edit profile). This auto-creates the record types + `VoidpenZone` in the **Development** environment.
- [ ] In CloudKit Dashboard, confirm record types `FoodEntry`, `FoodFavorite`, `WeightEntry`, `BodyFatEntry`, `ChatThread`, `UserProfile` exist with the expected fields and that `photo` is an Asset.

### Task 7.2: Multi-device behavior (Development)

- [ ] Device A add → appears on Device B (same iCloud account).
- [ ] Edit on B → updates on A (newer wins).
- [ ] Delete on A → removed on B.
- [ ] Food photo on A → image appears on B.
- [ ] Airplane-mode: edit the same entry differently on A and B, reconnect → the later `modifiedAt` wins; no duplicates.
- [ ] **Delete app on A, reinstall → all data (incl. photos) restores from iCloud.**
- [ ] Sign out of iCloud → app still works; Settings shows "iCloud unavailable"; no crash.

### Task 7.3: Deploy schema to Production (MANUAL — Dan)

- [ ] CloudKit Dashboard → **Deploy Schema Changes** from Development to **Production**.
- [ ] Set `aps-environment` to `production` for the App Store build.
- [ ] Verify on a TestFlight build that sync works (Production uses a separate data store from Development — a fresh verify is required).

### Task 7.4: Finish the branch

- [ ] Run the full unit suite: `cd ios && xcodebuild test -scheme calorietracker -destination 'platform=iOS Simulator,name=iPhone 16' -only-testing:calorietrackerTests`
- [ ] Use `superpowers:finishing-a-development-branch` to open the PR.

---

## Self-review notes (author)

- **Spec coverage:** §3 architecture → Phases 2,5; §4 data model/record types → Phases 1,3; §5 sync flows → Phase 5 (delegate) + Phase 2 (apply); §6 conflict → LWW in Phases 2,5; §7 error/edge → Task 5.3 `handleSendFailure`/`handleAccountChange`; §8 UI → Phase 6; §9 setup → Phase 4 + Task 7.3; §10 testing → Phases 1–3 unit + Phase 7 manual. All covered.
- **Photos:** included end-to-end (Tasks 3.1–3.3, CKAsset round-trip test).
- **No-migration guarantee:** preserved — local persistence paths untouched; only additive fields/methods.
- **Known soft spots flagged inline:** exact favorite add/remove method names (Task 2.6), `OptionalNutrientGoals` API (Task 3.6), and CKSyncEngine SDK signature drift (Phase 5 note) — each tells the implementer to read the real source first.
