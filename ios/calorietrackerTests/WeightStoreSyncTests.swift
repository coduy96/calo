import Testing
import Foundation
@testable import calorietracker

@Suite(.serialized) @MainActor
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
