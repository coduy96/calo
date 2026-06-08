# Always-on iCloud Sync — Design

**Date:** 2026-06-08
**Status:** Approved for planning
**Author:** Dan + Claude

## 1. Goal

Give every Voidpen user automatic, always-on, full-fidelity sync of their data
to Apple's cloud, so that:

- Data survives app deletion / device loss and restores on reinstall.
- The same data stays in sync across a user's iPhone and iPad live.
- No setup, no toggle, no paywall — it "just works," like Apple's own apps.

### Confirmed product decisions

| Decision | Choice |
| --- | --- |
| Sync model | Automatic, always-on (no user action) |
| Monetization | **Free for everyone** (uses each user's own iCloud quota, $0 server cost) |
| Data fidelity | **Everything, including photos** (food photos + weight progress photos via `CKAsset`) |
| Chat threads | **Included** in sync |
| Conflict policy | **Last-writer-wins** per record, by a `modifiedAt` timestamp |
| UI | Read-only status row in Settings; **no toggle** |

## 2. Current state (what exists today)

- **Local source of truth:** each store JSON-encodes its data into
  `UserDefaults.standard` (`FoodStore` → `foodEntries` / `favoriteFoodEntries`,
  `WeightStore`, `BodyFatStore`, `ChatStore`, `UserProfile` → `userProfile`,
  `OptionalNutrientGoals` → `optionalNutrientGoals`).
- **Photos** are written as JPEG files on disk via `FoodImageStore` and
  `WeightPhotoStore` (Application Support dir). Entries store only a *filename*;
  raw bytes never go into UserDefaults (~4 MiB cap).
- **Widget** reads a small snapshot from the App Group container
  `group.com.cotrinhhienduy.calorietracker`.
- **No data leaves the device.** The Supabase backend only records anonymous
  Gemini token usage; HealthKit is local.
- **Dead scaffolding already in the repo:**
  - `Services/CloudKitService.swift` (302 lines): naive `CKModifyRecords` /
    `CKQuery` "fetch all records, implicit last-write-wins." **Never wired** —
    nothing calls it. Photos explicitly skipped.
  - `FoodStore.mergeWithCloudEntries` / `WeightStore.mergeWithCloudEntries`:
    naive "cloud always wins" union by id, no timestamp check. **Never called.**
  - `calorietracker.entitlements` has iCloud keys present but the container
    array is **empty** — capability not actually active.
- **Deployment target: iOS 17.6** → `CKSyncEngine` (iOS 17+) is available.

## 3. Architecture (Approach A — `CKSyncEngine`)

Keep UserDefaults + on-disk JPEGs as the local source of truth (zero migration
risk). Add a thin sync layer on top.

```
User action ──> Store (FoodStore, WeightStore, …)
                  │  persist locally (UserDefaults + JPEG on disk)   ← unchanged
                  └─> CloudSyncCoordinator.recordLocalChange(type, id, deleted)
                            │
                       CKSyncEngine  ──(custom zone "VoidpenZone", private DB)──> iCloud
                            │
                  handleEvent(fetchedChanges | sentChanges | accountChange | stateUpdate)
                            │
                  SyncAdapter<T>  ──> Store.upsertFromCloud / deleteFromCloud  (LWW)
                            │
                  persist locally + write photo file + refresh widget snapshot + notify UI
```

### Components

1. **`CloudSyncCoordinator`** (`Services/Sync/CloudSyncCoordinator.swift`)
   - Owns the single `CKSyncEngine` pointed at one custom zone `VoidpenZone`
     in the **private** database of container
     `iCloud.com.cotrinhhienduy.calorietracker`.
   - Implements `CKSyncEngineDelegate`:
     - `nextRecordZoneChangeBatch` → asks the right adapter to build the
       `CKRecord` from current store state.
     - `handleEvent` → routes fetched/sent/account/state events.
   - Persists the engine's `CKSyncEngine.State.Serialization` blob locally
     (its own UserDefaults key / file).
   - Public API: `recordLocalChange(recordType:id:deleted:)`, `start()`,
     `handleRemoteNotification(_:)`, plus an observable `status`.

2. **`SyncAdapter` protocol + one adapter per record type**
   (`Services/Sync/Adapters/`). Each adapter knows:
   - its CloudKit `recordType`,
   - how to build a `CKRecord` from a model (including `CKAsset` for photos),
   - how to decode a `CKRecord` and apply it to its store via
     `upsertFromCloud` (LWW) or `deleteFromCloud(id:)`.
   This keeps the coordinator free of a giant per-type switch.

3. **Stores** — unchanged for local persistence. They gain:
   - emit `recordLocalChange` to the coordinator on **user-driven**
     add/update/delete only,
   - `upsertFromCloud(_:)` / `deleteFromCloud(id:)` that apply remote changes
     and persist **without** re-emitting (loop prevention),
   - existing naive `mergeWithCloudEntries` is replaced by timestamp-aware LWW.

4. **Models** — add `var modifiedAt: Date` where missing, bumped on every
   mutation. `ChatThread` already has `updatedAt` (reuse it).

5. **App wiring** (`calorietrackerApp.swift` + an `AppDelegate` adaptor):
   instantiate the coordinator at launch, hand it the stores, call `start()`,
   nudge sync on `didBecomeActive`, and forward silent pushes to the engine.

## 4. Data model & record types

Distinct record types so the same UUID can legitimately exist as both a logged
entry and a favorite without colliding (record IDs are namespaced by type
within the single zone):

| Record type | Source model | Key | Photo (`CKAsset`) | `modifiedAt` source |
| --- | --- | --- | --- | --- |
| `FoodEntry` | `FoodEntry` (logged) | `id` | yes (`imageFilename`) | **add field** |
| `FoodFavorite` | `FoodEntry` (favorite) | `id` | yes | **add field** |
| `WeightEntry` | `WeightEntry` | `id` | yes (`photoFilename`) | **add field** |
| `BodyFatEntry` | `BodyFatEntry` | `id` | no | **add field** |
| `ChatThread` | `ChatThread` | `id` | no | reuse `updatedAt` |
| `UserProfile` | `UserProfile` + `OptionalNutrientGoals` | singleton `"userProfile"` | no | **add field** |

Notes:

- `modifiedAt` is added as `var modifiedAt: Date` with a **Codable decode
  fallback** (`decodeIfPresent ?? .distantPast`) so existing stored rows that
  predate the field decode cleanly and are treated as oldest.
- **Photos:** a `CKAsset` is built from the existing on-disk JPEG. On inbound,
  the asset's bytes are written back through `FoodImageStore` /
  `WeightPhotoStore` and the filename stamped onto the row. The record also
  carries the logical filename string.
- **Deletes** need no local tombstone table — `CKSyncEngine` tracks what it has
  sent and propagates deletions itself.
- `UserProfile` + `OptionalNutrientGoals` are bundled into one singleton record
  to keep all "settings" together; both are small.

## 5. Sync flows

### Outbound (local → cloud)
1. User adds/edits/deletes → store mutates array, bumps `modifiedAt`, persists
   locally (exactly as today).
2. Store calls `coordinator.recordLocalChange(type, id, deleted)`.
3. Coordinator enqueues a `CKSyncEngine.PendingRecordZoneChange`
   (`.saveRecord` / `.deleteRecord`).
4. Engine calls back `nextRecordZoneChangeBatch` → adapter builds the `CKRecord`
   (with `CKAsset`) from **current** store state → engine sends (batched,
   retried, backed-off automatically).

### Inbound (cloud → local)
1. Engine delivers a `fetchedRecordZoneChanges` event.
2. For each modified record → adapter decodes → `store.upsertFromCloud`
   (overwrites the local row **only if** `cloud.modifiedAt >= local.modifiedAt`)
   → persist + write photo file → refresh widget snapshot → notify UI.
3. For each deleted record → `store.deleteFromCloud(id:)`.

### First sync on a device that already has local data AND cloud has data
This is the dangerous case. With no change token yet, the engine performs a full
pull → union-merge by id with LWW. Then every local row the engine doesn't know
about is enqueued as a pending save → push. **Net result is the union of both
sides, conflicts resolved by `modifiedAt`. No data loss in either direction.**

### Loop prevention
`upsertFromCloud` / `deleteFromCloud` must never call `recordLocalChange`. Only
user-driven mutations emit outbound changes.

## 6. Conflict resolution

- **Last-writer-wins per record, by `modifiedAt`.**
  - Inbound merge: overwrite local only if `cloud.modifiedAt >= local.modifiedAt`.
  - On a server conflict during send (`CKSyncEngine` surfaces the server
    record), compare timestamps; newer wins; re-send if local is newer.
- A delete propagated by the engine wins over an older edit. A re-add with a
  newer `modifiedAt` intentionally resurrects.
- Rationale: single-user personal data; field-level merge adds complexity with
  no real benefit here.

## 7. Error handling / edge cases

| Situation | Behavior |
| --- | --- |
| No iCloud account / restricted | Sync silently no-ops; app fully works locally. Status row: "iCloud unavailable." No nagging. |
| Account switch (different Apple ID) | Handle engine `accountChange` event: keep local data, reset zone/state for the new account. |
| iCloud quota full | Keep local data; gentle status; engine retries later. Never blocks local use. |
| Photo asset upload/download failure | Row still syncs; photo fills in on a later sync (asset failures decoupled from row sync). |
| Network / throttling | Handled by `CKSyncEngine` backoff. |
| Widget | App Group snapshot rewritten after merges, so the widget reflects synced data. |

## 8. UI surface (minimal — free & always-on)

One read-only status row in Settings:

> **iCloud Sync** — *Syncing… / Up to date · last synced ⟨time⟩ / iCloud unavailable*

No toggle, no paywall wiring. An optional dev-only "Sync now" affordance behind
a debug flag.

## 9. Project / capability setup (one-time)

1. Add `iCloud.com.cotrinhhienduy.calorietracker` to the (currently empty)
   `com.apple.developer.icloud-container-identifiers` and set
   `com.apple.developer.icloud-services` → `CloudKit` in
   `calorietracker.entitlements`.
2. Ensure both build configs can use the container. Note **Debug bundle ID is
   `com.cotrinhhienduy.calorietracker.debug`** while Release is
   `com.cotrinhhienduy.calorietracker`; the CloudKit container identifier is
   explicit and shared, but the entitlement must be present on whichever config
   is being tested.
3. Add `remote-notification` to `UIBackgroundModes` (Info.plist) for silent-push
   wake; forward the push to the engine in the app delegate. `aps-environment`
   is already present (development); switch to production at release.
4. CloudKit Dashboard: let the schema auto-create in **Development**, then
   **deploy schema to Production** and verify on a TestFlight build before
   release (avoids the classic "works in dev, empty in prod" trap).

## 10. Testing plan

### Unit
- Record ↔ model round-trip for each type (incl. asset filename + optional
  nutrient fields).
- LWW merge: older cloud must **not** clobber newer local; newer cloud wins.
- Deletion application.
- Legacy decode: data lacking `modifiedAt` decodes and is treated as oldest.

### Manual / multi-device (Release build, real iCloud account)
- Add on device A → appears on B.
- Edit on B → updates A.
- Delete on A → gone on B.
- Offline edits on both sides → newer wins on reconnect.
- **Reinstall app → full restore incl. photos.**
- No iCloud account → app works, status shows unavailable.

## 11. Out of scope (this iteration)

- Sharing data between different users (CKShare).
- Conflict UI / manual merge resolution.
- Selective/partial sync or a user-facing on/off toggle.
- Migrating local storage to Core Data / SwiftData.

## 12. Risks

- **CloudKit Dev vs Prod schema** mismatch at release — mitigated by step 9.4.
- **Asset volume / quota** for heavy photo users — acceptable (their own quota);
  asset failures are non-fatal.
- **Integration churn in the stores** — mitigated by keeping local persistence
  untouched and adding sync as a separate, well-bounded layer.
