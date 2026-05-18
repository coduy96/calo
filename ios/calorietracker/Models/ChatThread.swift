import Foundation

/// One Coach conversation. The Coach tab shows a list of these; tapping one pushes
/// into ChatView to read/continue the conversation. Title is auto-derived from the
/// first user message but can be renamed by the user.
struct ChatThread: Identifiable, Codable, Equatable {
    let id: UUID
    var title: String
    var messages: [ChatMessage]
    let createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        title: String = "",
        messages: [ChatMessage] = [],
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.messages = messages
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var lastMessagePreview: String {
        messages.last?.content ?? ""
    }
}
