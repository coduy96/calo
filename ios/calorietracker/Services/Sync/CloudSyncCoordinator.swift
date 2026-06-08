import Foundation
import CloudKit
import os

/// User-visible iCloud sync state, surfaced in Settings.
enum CloudSyncStatus: Equatable {
    case idle, syncing
    case upToDate(Date?)
    case unavailable
    case error(String)
}

/// Drives Apple's `CKSyncEngine` for Voidpen's private-database zone.
///
/// The coordinator owns the engine, persists its serialized state, materializes
/// `CKRecord`s from the live stores on demand (in the delegate), and routes
/// incoming changes back into the stores. It is the single integration point
/// between local data and CloudKit.
@MainActor
@Observable
final class CloudSyncCoordinator {
    static let containerID = "iCloud.com.cotrinhhienduy.calorietracker"
    static let zoneName = "VoidpenZone"
    static let stateKey = "ckSyncEngineState"
    private static let lastSyncKey = "ckSyncLastSuccess"

    private(set) var status: CloudSyncStatus = .idle

    /// True only while `applyIncomingProfile` is writing an inbound cloud profile
    /// to disk. The profile save posts `.userProfileDidChange`, which the app's
    /// `.onReceive` would otherwise turn into a redundant outbound push (an echo).
    /// The app reads this via `isApplyingInboundProfile` to skip that push.
    private(set) var isApplyingInboundProfile = false

    let stores: SyncStores
    private let container: CKContainer
    private let zoneID: CKRecordZone.ID
    private var engine: CKSyncEngine?

    /// Records reconstructed during conflict resolution that must be sent WITH
    /// the server's change tag (not a fresh tagless record). Keyed by recordID
    /// and consumed once by `nextRecordZoneChangeBatch`. Without this, a save
    /// that loses a `serverRecordChanged` race would re-send a tagless record
    /// and conflict again forever — the loop that prevented chat *updates* from
    /// ever syncing.
    @ObservationIgnored
    var resolvedConflictRecords: [CKRecord.ID: CKRecord] = [:]
    let log = Logger(subsystem: "com.cotrinhhienduy.calorietracker", category: "sync")

    init(stores: SyncStores) {
        self.stores = stores
        self.container = CKContainer(identifier: Self.containerID)
        self.zoneID = CKRecordZone.ID(zoneName: Self.zoneName, ownerName: CKCurrentUserDefaultName)
    }

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
        Task { await self.pushAllLocal() }
    }

    /// Tear down the live engine and rebuild it from persisted state. Called on
    /// account change after `removeObject(forKey: stateKey)` so the rebuilt
    /// engine starts with `stateSerialization: nil` (no stale sync tokens bound
    /// to the previous account). `start()`'s `guard engine == nil` makes the
    /// rebuild safe: nil-ing first lets `start()` create a fresh engine.
    func resetEngine() {
        engine = nil
        start()
    }

    /// Record an outbound local mutation reported by a store.
    ///
    /// If no engine exists yet (mutation arrived before `start()`), the change is
    /// dropped here — but that's fine: `pushAllLocal()` runs at startup and reads
    /// the current store state, so any pre-`start()` mutation is still uploaded.
    func record(_ mutation: SyncMutation) {
        guard let engine else { return }
        let recordID = CKRecord.ID(recordName: mutation.kind.recordName(for: mutation.id), zoneID: zoneID)
        let change: CKSyncEngine.PendingRecordZoneChange = mutation.deleted ? .deleteRecord(recordID) : .saveRecord(recordID)
        engine.state.add(pendingRecordZoneChanges: [change])
    }

    /// Record an outbound profile change (singleton record).
    func recordProfileChange() {
        guard let engine else { return }
        let recordID = CKRecord.ID(recordName: SyncRecordKind.profile.fixedRecordName, zoneID: zoneID)
        engine.state.add(pendingRecordZoneChanges: [.saveRecord(recordID)])
    }

    // MARK: - State persistence

    func loadState() -> CKSyncEngine.State.Serialization? {
        guard let data = UserDefaults.standard.data(forKey: Self.stateKey) else { return nil }
        return try? JSONDecoder().decode(CKSyncEngine.State.Serialization.self, from: data)
    }

    func saveState(_ serialization: CKSyncEngine.State.Serialization) {
        if let data = try? JSONEncoder().encode(serialization) {
            UserDefaults.standard.set(data, forKey: Self.stateKey)
        }
    }

    func markSynced() {
        let now = Date()
        UserDefaults.standard.set(now, forKey: Self.lastSyncKey)
        status = .upToDate(now)
    }

    // MARK: - Full push

    /// Queue every local record for upload. Used at startup, on sign-in/account
    /// switch, and after zone re-creation. This unconditionally enqueues all
    /// records; the engine dedupes and LWW makes redundant pushes no-ops, so it
    /// is safe to call repeatedly.
    func pushAllLocal() async {
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

    func id(_ kind: SyncRecordKind, _ uuid: UUID) -> CKRecord.ID {
        CKRecord.ID(recordName: kind.recordName(for: uuid), zoneID: zoneID)
    }

    var recordZoneID: CKRecordZone.ID { zoneID }

    // MARK: - Full cloud wipe

    /// Delete the entire CloudKit zone so a "Delete All Data" wipe doesn't get
    /// resurrected from iCloud on the next sync. Enqueues a zone deletion on the
    /// engine, then flushes it with `sendChanges()` so the delete actually goes
    /// out to the server before the caller clears local state.
    ///
    /// `async` because `CKSyncEngine.sendChanges(_:)` is awaitable — awaiting it
    /// guarantees the zone-delete is sent (or at least attempted) before the
    /// Delete-All-Data flow tears down `ckSyncEngineState` and local stores.
    /// Without the flush the delete would only leave on the next `automaticallySync`
    /// opportunity, which may never come if the user immediately re-onboards.
    ///
    /// On the re-onboard path the engine is later recreated with nil state and an
    /// empty zone is recreated on first push; `pushAllLocal()` then uploads the
    /// (now empty) stores, so nothing resurrects.
    ///
    /// If `sendChanges()` throws (offline, not authenticated), the delete stays
    /// pending in the engine's serialized state and will flush on the next sync
    /// opportunity — the local wipe still proceeds either way.
    func deleteAllCloudData() async {
        guard let engine else { return }
        engine.state.add(pendingDatabaseChanges: [.deleteZone(zoneID)])
        do {
            // Default scope `.all` flushes the pending database change (the zone
            // delete) along with any pending record-zone changes; the zone delete
            // supersedes everything in it server-side.
            try await engine.sendChanges()
        } catch {
            log.error("deleteAllCloudData: sendChanges failed, zone delete left pending: \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Mutate `status` from the delegate extension.
    func setStatus(_ newStatus: CloudSyncStatus) { status = newStatus }

    /// Set the inbound-profile echo guard from the delegate extension.
    func setApplyingInboundProfile(_ applying: Bool) { isApplyingInboundProfile = applying }
}
