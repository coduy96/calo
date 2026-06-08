import Foundation
import CloudKit
import os

extension CloudSyncCoordinator: CKSyncEngineDelegate {

    // MARK: - Outbound: build the next batch

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

    /// Build a fresh `CKRecord` from CURRENT store state. Returns nil to drop a
    /// pending change whose underlying model no longer exists (the engine then
    /// discards it rather than uploading stale data).
    private func materialize(recordID: CKRecord.ID) async -> CKRecord? {
        let name = recordID.recordName
        if name == SyncRecordKind.profile.fixedRecordName {
            guard let profile = UserProfile.load() else { return nil }
            return ProfileRecordMapper.record(from: profile, zoneID: recordZoneID)
        }
        guard let (kind, uuid) = SyncRecordKind.parse(recordName: name) else { return nil }
        switch kind {
        case .food:
            guard let e = stores.food.entries.first(where: { $0.id == uuid }) else { return nil }
            return FoodRecordMapper.record(from: e, kind: .food, zoneID: recordZoneID)
        case .favorite:
            guard let f = stores.food.favorites.first(where: { $0.id == uuid }) else { return nil }
            return FoodRecordMapper.record(from: f, kind: .favorite, zoneID: recordZoneID)
        case .weight:
            guard let w = stores.weight.entries.first(where: { $0.id == uuid }) else { return nil }
            return WeightRecordMapper.record(from: w, zoneID: recordZoneID)
        case .bodyFat:
            guard let b = stores.bodyFat.entries.first(where: { $0.id == uuid }) else { return nil }
            return BodyFatRecordMapper.record(from: b, zoneID: recordZoneID)
        case .chat:
            guard let t = stores.chat.threads.first(where: { $0.id == uuid }) else { return nil }
            return ChatRecordMapper.record(from: t, zoneID: recordZoneID)
        case .profile:
            return nil
        }
    }

    // MARK: - Events

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
            setStatus(.syncing)
        case .didFetchChanges, .didSendChanges:
            markSynced()
        case .fetchedDatabaseChanges, .sentDatabaseChanges,
             .willFetchRecordZoneChanges, .didFetchRecordZoneChanges:
            break
        @unknown default:
            break
        }
    }

    // MARK: - Inbound: apply server changes to stores

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
        incoming.savePreservingTimestamp()
    }

    private func applyIncomingDelete(recordName: String) {
        if recordName == SyncRecordKind.profile.fixedRecordName { return }
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

    // MARK: - Send failures

    private func handleSendFailure(record: CKRecord, error: CKError, syncEngine: CKSyncEngine) {
        switch error.code {
        case .serverRecordChanged:
            // Last-writer-wins by modifiedAt. If the server copy is newer (or
            // equal), accept it locally; otherwise re-queue our save to overwrite.
            if let serverRecord = error.serverRecord,
               let serverStamp = serverRecord["modifiedAt"] as? Date,
               let localStamp = record["modifiedAt"] as? Date,
               localStamp <= serverStamp {
                applyIncoming(serverRecord)
            } else {
                syncEngine.state.add(pendingRecordZoneChanges: [.saveRecord(record.recordID)])
            }
        case .zoneNotFound, .userDeletedZone:
            // Zone is gone server-side. Re-create it and push everything again.
            syncEngine.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: recordZoneID))])
            Task { await pushAllLocalIfFreshZone() }
        case .notAuthenticated, .accountTemporarilyUnavailable:
            setStatus(.unavailable)
        case .quotaExceeded:
            setStatus(.error("iCloud storage full"))
        default:
            log.error("Unhandled send failure for \(record.recordID.recordName, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Account changes

    private func handleAccountChange(_ e: CKSyncEngine.Event.AccountChange) async {
        switch e.changeType {
        case .signIn:
            // New account signed in: push all local data up to the new account.
            await pushAllLocalIfFreshZone()
        case .switchAccounts, .signOut:
            // Different/no account: drop the engine's sync state so we don't
            // mingle data, but keep the local data intact on this device.
            UserDefaults.standard.removeObject(forKey: CloudSyncCoordinator.stateKey)
            setStatus(.unavailable)
        @unknown default:
            break
        }
    }
}
