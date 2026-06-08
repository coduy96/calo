import Testing
import Foundation
@testable import calorietracker

@Suite(.serialized) @MainActor
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
