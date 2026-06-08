import Foundation
import CloudKit

/// Maps BodyFatEntry ↔ CKRecord.
enum BodyFatRecordMapper {

    static func record(from entry: BodyFatEntry, zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(
            recordName: SyncRecordKind.bodyFat.recordName(for: entry.id),
            zoneID: zoneID
        )
        let record = CKRecord(recordType: SyncRecordKind.bodyFat.recordType, recordID: recordID)
        record["entryID"] = entry.id.uuidString
        record["date"] = entry.date
        record["bodyFatFraction"] = entry.bodyFatFraction
        record["modifiedAt"] = entry.modifiedAt
        return record
    }

    static func bodyFatEntry(from record: CKRecord) -> BodyFatEntry? {
        guard let idString = record["entryID"] as? String,
              let id = UUID(uuidString: idString),
              let date = record["date"] as? Date,
              let fraction = record["bodyFatFraction"] as? Double
        else { return nil }

        return BodyFatEntry(
            id: id,
            date: date,
            bodyFatFraction: fraction,
            modifiedAt: record["modifiedAt"] as? Date
        )
    }
}
