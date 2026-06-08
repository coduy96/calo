import Testing
import Foundation
@testable import calorietracker

@Suite(.serialized) @MainActor
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
