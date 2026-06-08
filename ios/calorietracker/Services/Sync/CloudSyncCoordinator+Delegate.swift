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
            // `failedRecordDeletes` is a [CKRecord.ID: CKError] dictionary on
            // SentRecordZoneChanges. A delete can't raise `.serverRecordChanged`,
            // so there's no LWW to apply here — the record is already gone locally.
            for (recordID, error) in e.failedRecordDeletes {
                handleDeleteFailure(recordID: recordID, error: error, syncEngine: syncEngine)
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
        // `savePreservingTimestamp()` posts `.userProfileDidChange`; guard the
        // app's listener so applying this inbound profile doesn't trigger a
        // redundant outbound push (echo).
        setApplyingInboundProfile(true)
        incoming.savePreservingTimestamp()
        setApplyingInboundProfile(false)
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
            //
            // Note: chat records carry no top-level `modifiedAt` field — their LWW
            // key is `updatedAt` inside the JSON payload — so for chat the
            // `localStamp` lookup below is nil and this falls through to the
            // re-enqueue branch. That's acceptable: inbound chat LWW still applies
            // correctly via `updatedAt` in `applyIncoming` / the store upsert.
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
            Task { await pushAllLocal() }
        case .notAuthenticated, .accountTemporarilyUnavailable:
            setStatus(.unavailable)
        case .quotaExceeded:
            setStatus(.error("iCloud storage full"))
        default:
            log.error("Unhandled send failure for \(record.recordID.recordName, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    /// Handle a failed DELETE reported in `failedRecordDeletes`. The record is
    /// already gone locally, so there's nothing to re-push per-record. On a
    /// missing/deleted zone we recreate it and re-push all surviving local
    /// records; everything else is logged.
    private func handleDeleteFailure(recordID: CKRecord.ID, error: CKError, syncEngine: CKSyncEngine) {
        switch error.code {
        case .zoneNotFound, .userDeletedZone:
            // Zone is gone server-side. Re-create it and re-push all surviving
            // local records. The deleted record is already gone locally, so it
            // simply won't be among them — no per-record re-push needed.
            syncEngine.state.add(pendingDatabaseChanges: [.saveZone(CKRecordZone(zoneID: recordZoneID))])
            Task { await pushAllLocal() }
        case .notAuthenticated, .accountTemporarilyUnavailable:
            setStatus(.unavailable)
        case .unknownItem:
            // Server already has no such record — the delete is effectively done.
            break
        default:
            log.error("Unhandled delete failure for \(recordID.recordName, privacy: .public): \(error.localizedDescription, privacy: .public)")
        }
    }

    // MARK: - Account changes

    private func handleAccountChange(_ e: CKSyncEngine.Event.AccountChange) async {
        // CKSyncEngine does NOT reset its own in-memory state on an account
        // change — per Apple's `sample-cloudkit-sync-engine`, the app must
        // re-initialize the engine to flush state bound to the previous account.
        // We clear persisted state first, then rebuild the engine via
        // `resetEngine()` so it comes back with `stateSerialization: nil` (no
        // stale sync tokens). The teardown/rebuild and re-push are dispatched on
        // a fresh task hop because `handleEvent` is mid-callback on the live
        // engine — deallocating it inside its own callback would be unsafe.
        switch e.changeType {
        case .signIn:
            // New account signed in: push all local data up to the new account.
            // No engine reset needed — there was no prior account state to flush.
            await pushAllLocal()
        case .switchAccounts:
            // Different account is now active. Drop persisted state, rebuild the
            // engine, and re-push all local data so the newly-active account
            // receives this device's data. Local data is kept intact.
            UserDefaults.standard.removeObject(forKey: CloudSyncCoordinator.stateKey)
            Task { @MainActor in
                self.resetEngine()
                await self.pushAllLocal()
            }
        case .signOut:
            // No account: drop persisted state and rebuild the engine so no
            // stale tokens linger, then mark unavailable. Local data is kept.
            UserDefaults.standard.removeObject(forKey: CloudSyncCoordinator.stateKey)
            Task { @MainActor in
                self.resetEngine()
                self.setStatus(.unavailable)
            }
        @unknown default:
            break
        }
    }
}
