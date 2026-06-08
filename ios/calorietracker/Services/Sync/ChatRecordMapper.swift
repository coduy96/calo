import Foundation
import CloudKit

/// Maps ChatThread ↔ CKRecord.
///
/// The whole thread (title, messages array, timestamps) is encoded as a JSON
/// string in the "payload" field.  Before encoding, `attachmentImageData` is
/// stripped from every message so the payload stays well under CloudKit's
/// ~1 MB per-field limit.  Chat image thumbnails are device-local analysis
/// artifacts — text + structure syncs, attachments do not.
enum ChatRecordMapper {

    static func record(from thread: ChatThread, zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(
            recordName: SyncRecordKind.chat.recordName(for: thread.id),
            zoneID: zoneID
        )
        let record = CKRecord(recordType: SyncRecordKind.chat.recordType, recordID: recordID)
        record["threadID"] = thread.id.uuidString
        record["updatedAt"] = thread.updatedAt

        // Strip inline image bytes so the payload stays under CloudKit's ~1 MB field cap.
        var lean = thread
        lean.messages = thread.messages.map { msg in
            ChatMessage(
                id: msg.id,
                role: msg.role,
                content: msg.content,
                timestamp: msg.timestamp,
                attachmentImageData: nil
            )
        }
        if let data = try? JSONEncoder().encode(lean) {
            record["payload"] = String(decoding: data, as: UTF8.self)
        }
        return record
    }

    static func chatThread(from record: CKRecord) -> ChatThread? {
        guard let payload = record["payload"] as? String,
              let data = payload.data(using: .utf8),
              let thread = try? JSONDecoder().decode(ChatThread.self, from: data)
        else { return nil }
        return thread
    }
}
