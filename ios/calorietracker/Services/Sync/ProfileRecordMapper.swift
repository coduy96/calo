import Foundation
import CloudKit

/// Maps UserProfile ↔ CKRecord (singleton — always recordName "profile").
///
/// The full UserProfile is encoded as a JSON payload string.
///
/// OptionalNutrientGoals decision: INCLUDED as a second field "optionalGoals".
/// Its API is clean — `OptionalNutrientGoals` is Codable, `encodedData` gives
/// a JSON Data blob, and `OptionalNutrientGoals.decoded(from:)` restores it.
/// On restore, `OptionalNutrientGoals.save(_:)` is called to update UserDefaults
/// so the rest of the app picks up the synced goals immediately.
enum ProfileRecordMapper {

    static func record(from profile: UserProfile, zoneID: CKRecordZone.ID) -> CKRecord {
        let recordID = CKRecord.ID(
            recordName: SyncRecordKind.profile.fixedRecordName,
            zoneID: zoneID
        )
        let record = CKRecord(recordType: SyncRecordKind.profile.recordType, recordID: recordID)
        record["modifiedAt"] = profile.modifiedAt
        if let data = try? JSONEncoder().encode(profile) {
            record["payload"] = String(decoding: data, as: UTF8.self)
        }
        // Encode current OptionalNutrientGoals alongside the profile.
        let goalsData = OptionalNutrientGoals.current.encodedData
        if !goalsData.isEmpty {
            record["optionalGoals"] = String(decoding: goalsData, as: UTF8.self)
        }
        return record
    }

    static func profile(from record: CKRecord) -> UserProfile? {
        guard let payload = record["payload"] as? String,
              let data = payload.data(using: .utf8),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data)
        else { return nil }

        // Restore OptionalNutrientGoals if present.
        if let goalsString = record["optionalGoals"] as? String,
           let goalsData = goalsString.data(using: .utf8) {
            let goals = OptionalNutrientGoals.decoded(from: goalsData)
            OptionalNutrientGoals.save(goals)
        }

        return profile
    }
}
