import Testing
import Foundation
import CloudKit
@testable import calorietracker

struct ChatRecordMapperTests {
    private let zoneID = CKRecordZone.ID(zoneName: "VoidpenZone", ownerName: CKCurrentUserDefaultName)

    @Test func roundTrip() throws {
        let t = ChatThread(
            title: "Diet Qs",
            messages: [
                ChatMessage(role: .user, content: "hi"),
                ChatMessage(role: .assistant, content: "hello")
            ],
            createdAt: Date(timeIntervalSince1970: 1),
            updatedAt: Date(timeIntervalSince1970: 2)
        )
        let rec = ChatRecordMapper.record(from: t, zoneID: zoneID)
        #expect(rec.recordType == "ChatThread")
        #expect(rec.recordID.recordName == "chat_\(t.id.uuidString)")
        let back = try #require(ChatRecordMapper.chatThread(from: rec))
        #expect(back.id == t.id)
        #expect(back.title == "Diet Qs")
        #expect(back.messages.count == 2)
        #expect(back.messages.last?.content == "hello")
        #expect(back.updatedAt == t.updatedAt)
    }

    @Test func stripsAttachmentImageData() throws {
        let withImage = ChatMessage(
            role: .user,
            content: "look",
            attachmentImageData: Data([0x1, 0x2, 0x3])
        )
        let t = ChatThread(title: "x", messages: [withImage], createdAt: .now, updatedAt: .now)
        let rec = ChatRecordMapper.record(from: t, zoneID: zoneID)
        let back = try #require(ChatRecordMapper.chatThread(from: rec))
        #expect(back.messages.first?.attachmentImageData == nil)
        #expect(back.messages.first?.content == "look")
    }
}
