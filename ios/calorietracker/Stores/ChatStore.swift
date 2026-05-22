import Foundation
import SwiftUI

/// Persists Coach conversations as a list of threads. Each thread is one conversation;
/// the user can open many in parallel from the history list. The full history of every
/// thread survives app restarts, but the per-call context window sent to the LLM is
/// capped at `maxMessagesInContext` to control token cost.
@Observable
class ChatStore {
    private(set) var threads: [ChatThread] = []

    private let storageKey = "coachChatThreads"
    /// Per-thread cap on the trailing slice sent to the LLM. The system prompt is built
    /// separately each turn so the context stays fresh as the user logs more food/weights.
    static let maxMessagesInContext = 20

    /// First N characters of the first user message used as an auto-generated title.
    private static let titleCharacterBudget = 40

    init() {
        load()
    }

    // MARK: - Read

    /// Threads with at least one message, newest activity first. Draft threads
    /// (created via `createDraftThread` but never sent to) are hidden from the list.
    var visibleThreads: [ChatThread] {
        threads
            .filter { !$0.messages.isEmpty }
            .sorted { $0.updatedAt > $1.updatedAt }
    }

    func thread(id: UUID) -> ChatThread? {
        threads.first(where: { $0.id == id })
    }

    /// Trailing slice of messages in a thread to send as conversation history to the LLM.
    func contextMessages(for threadID: UUID) -> [ChatMessage] {
        guard let thread = thread(id: threadID) else { return [] }
        return Array(thread.messages.suffix(Self.maxMessagesInContext))
    }

    // MARK: - Mutation

    /// Inserts an empty thread and returns it. The thread is hidden from `visibleThreads`
    /// until at least one message is appended; if the user navigates away without sending,
    /// `deleteIfEmpty` should be called to clean up.
    @discardableResult
    func createDraftThread() -> ChatThread {
        let draft = ChatThread()
        threads.append(draft)
        save()
        return draft
    }

    func append(_ message: ChatMessage, to threadID: UUID) {
        guard let idx = threads.firstIndex(where: { $0.id == threadID }) else { return }
        threads[idx].messages.append(message)
        threads[idx].updatedAt = .now
        // Auto-title from the first user message, but only if the user hasn't named the thread yet.
        if threads[idx].title.isEmpty, message.role == .user {
            threads[idx].title = autoTitle(from: message.content)
        }
        save()
    }

    /// Replace the last assistant message in a thread. Useful for error-fix retries.
    func replaceLastAssistant(in threadID: UUID, with content: String) {
        guard let tIdx = threads.firstIndex(where: { $0.id == threadID }) else { return }
        guard let mIdx = threads[tIdx].messages.lastIndex(where: { $0.role == .assistant }) else { return }
        let old = threads[tIdx].messages[mIdx]
        threads[tIdx].messages[mIdx] = ChatMessage(
            id: old.id,
            role: .assistant,
            content: content,
            timestamp: old.timestamp,
            attachmentImageData: old.attachmentImageData
        )
        threads[tIdx].updatedAt = .now
        save()
    }

    func rename(threadID: UUID, to title: String) {
        guard let idx = threads.firstIndex(where: { $0.id == threadID }) else { return }
        let trimmed = title.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        threads[idx].title = trimmed
        save()
    }

    func delete(threadID: UUID) {
        threads.removeAll { $0.id == threadID }
        save()
    }

    /// Removes the thread only if it has no messages — used to clean up drafts that
    /// the user opened from the history list but never sent a message in.
    func deleteIfEmpty(_ threadID: UUID) {
        guard let idx = threads.firstIndex(where: { $0.id == threadID }) else { return }
        guard threads[idx].messages.isEmpty else { return }
        threads.remove(at: idx)
        save()
    }

    func reset() {
        threads = []
        save()
    }

    // MARK: - Helpers

    private func autoTitle(from rawContent: String) -> String {
        let collapsed = rawContent
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        if collapsed.count <= Self.titleCharacterBudget { return collapsed }
        let endIndex = collapsed.index(collapsed.startIndex, offsetBy: Self.titleCharacterBudget)
        return collapsed[..<endIndex].trimmingCharacters(in: .whitespacesAndNewlines) + "…"
    }

    // MARK: - Persistence

    private func save() {
        if let data = try? JSONEncoder().encode(threads) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    /// Re-read threads from UserDefaults. Used after MockDataSeeder rewrites
    /// the store key so the live @State instance picks up the new data.
    func reloadFromDisk() {
        threads = []
        load()
    }

    private func load() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([ChatThread].self, from: data)
        else { return }
        threads = decoded
    }
}
