import Foundation
import CloudKit

/// Maps WeightEntry ↔ CKRecord.
/// Photos travel as CKAsset pointing at the persistent WeightPhotoStore file;
/// on decode the bytes are written back to the store under the same filename.
enum WeightRecordMapper {

    static func record(from entry: WeightEntry, zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(
            recordName: SyncRecordKind.weight.recordName(for: entry.id),
            zoneID: zoneID
        )
        let record = CKRecord(recordType: SyncRecordKind.weight.recordType, recordID: recordID)
        record["entryID"] = entry.id.uuidString
        record["date"] = entry.date
        record["weightKg"] = entry.weightKg
        record["modifiedAt"] = entry.modifiedAt
        if let filename = entry.photoFilename,
           let url = WeightPhotoStore.shared.fileURL(for: filename),
           FileManager.default.fileExists(atPath: url.path) {
            record["photoFilename"] = filename
            record["photo"] = CKAsset(fileURL: url)
        }
        return record
    }

    static func weightEntry(from record: CKRecord) -> WeightEntry? {
        guard let idString = record["entryID"] as? String,
              let id = UUID(uuidString: idString),
              let date = record["date"] as? Date,
              let weightKg = record["weightKg"] as? Double
        else { return nil }

        let photoFilename = record["photoFilename"] as? String
        if photoFilename != nil,
           let asset = record["photo"] as? CKAsset,
           let url = asset.fileURL,
           let data = try? Data(contentsOf: url) {
            _ = WeightPhotoStore.shared.store(data: data, for: id)
        }

        return WeightEntry(
            id: id,
            date: date,
            weightKg: weightKg,
            photoFilename: photoFilename,
            modifiedAt: record["modifiedAt"] as? Date
        )
    }
}
