import Testing
import Foundation
@testable import calorietracker

@Suite(.serialized) @MainActor struct FoodStoreSyncTests {
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

    @Test func applyCloudUpsertNewerClobbersOlderLocal() {
        let store = freshStore()
        let id = UUID()
        let old = FoodEntry(id: id, name: "Old", calories: 100, protein: 0, carbs: 0, fat: 0, source: .manual, modifiedAt: Date(timeIntervalSince1970: 0))
        store.applyCloudUpsert(old)
        let newer = FoodEntry(id: id, name: "New", calories: 200, protein: 0, carbs: 0, fat: 0, source: .manual, modifiedAt: Date())
        store.applyCloudUpsert(newer)
        #expect(store.entries.first { $0.id == id }?.name == "New")
        #expect(store.entries.first { $0.id == id }?.calories == 200)
    }

    @Test func toggleFavoriteRemoveEmitsDeletedMutation() {
        let store = freshStore()
        let e = FoodEntry(name: "Fav", calories: 50, protein: 0, carbs: 0, fat: 0, source: .manual)
        store.toggleFavorite(e)          // add
        var m: SyncMutation?
        store.onSyncMutation = { if $0.kind == .favorite { m = $0 } }
        store.toggleFavorite(e)          // remove
        #expect(m?.deleted == true)
        #expect(m?.kind == .favorite)
    }

    @Test func applyCloudUpsertRepopulatesImageDataFromDisk() {
        let store = freshStore()
        let id = UUID()
        // Image bytes already on disk under the entry's id — exactly what
        // FoodRecordMapper writes when it decodes a cloud record's CKAsset.
        let jpeg = Data([0xFF, 0xD8, 0xFF, 0xD9])
        let filename = FoodImageStore.shared.store(data: jpeg, for: id)!
        defer { FoodImageStore.shared.delete(filename: filename) }
        // A cloud-decoded entry arrives with imageData == nil but imageFilename set.
        let incoming = FoodEntry(id: id, name: "Photo meal", calories: 1, protein: 0, carbs: 0, fat: 0,
                                 imageData: nil, imageFilename: filename, source: .manual, modifiedAt: Date())
        store.applyCloudUpsert(incoming)
        // The food-log UI renders entry.imageData, so it must be repopulated from disk.
        #expect(store.entries.first { $0.id == id }?.imageData == jpeg)
    }

    @Test func applyCloudFavoriteUpsertRepopulatesImageDataFromDisk() {
        let store = freshStore()
        let id = UUID()
        let jpeg = Data([0xFF, 0xD8, 0xFF, 0xD9])
        let filename = FoodImageStore.shared.store(data: jpeg, for: id)!
        defer { FoodImageStore.shared.delete(filename: filename) }
        let incoming = FoodEntry(id: id, name: "Fav photo", calories: 1, protein: 0, carbs: 0, fat: 0,
                                 imageData: nil, imageFilename: filename, source: .manual, modifiedAt: Date())
        store.applyCloudFavoriteUpsert(incoming)
        #expect(store.favorites.first { $0.id == id }?.imageData == jpeg)
    }
}
