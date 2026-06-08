import Testing
import Foundation
import CloudKit
@testable import calorietracker

struct ProfileRecordMapperTests {
    private let zoneID = CKRecordZone.ID(zoneName: "VoidpenZone", ownerName: CKCurrentUserDefaultName)

    @Test func roundTripsOptionalNutrientGoals() throws {
        // Build goals with a non-default fiber value (45 g — in range 5…100, step 5).
        var goals = OptionalNutrientGoals.defaults
        goals.setGoal(45, for: .fiber)

        // Construct the CKRecord in-process, mirroring exactly what
        // ProfileRecordMapper.record(from:zoneID:) does for the optionalGoals field.
        // We do NOT call record(from:zoneID:) here because that method reads
        // OptionalNutrientGoals.current from UserDefaults.standard, which is shared
        // across parallel xcodebuild clones and causes non-deterministic failures.
        let recID = CKRecord.ID(recordName: "profile", zoneID: zoneID)
        let rec   = CKRecord(recordType: "UserProfile", recordID: recID)
        var p = UserProfile.default
        p.modifiedAt = Date(timeIntervalSince1970: 1_700_000_000)
        if let data = try? JSONEncoder().encode(p) {
            rec["payload"] = String(decoding: data, as: UTF8.self)
        }
        // This is the exact line from ProfileRecordMapper.record(from:zoneID:):
        rec["optionalGoals"] = String(decoding: goals.encodedData, as: UTF8.self)

        // ── Decode path ──────────────────────────────────────────────────────────
        // Decode the optionalGoals field directly (exercises decoded(from:) +
        // mergedWithDefaults()).  All in-memory — no UserDefaults read or write.
        let goalsString = try #require(rec["optionalGoals"] as? String)
        let goalsData   = try #require(goalsString.data(using: .utf8))
        let restored    = OptionalNutrientGoals.decoded(from: goalsData)
        #expect(restored.goal(for: .fiber) == 45)

        // Also exercise the full profile(from:) mapper to ensure it succeeds.
        _ = try #require(ProfileRecordMapper.profile(from: rec))
    }

    @Test func roundTrip() throws {
        var p = UserProfile.default
        p.weightKg = 78
        p.modifiedAt = Date(timeIntervalSince1970: 1_700_000_000)
        let rec = ProfileRecordMapper.record(from: p, zoneID: zoneID)
        #expect(rec.recordType == "UserProfile")
        #expect(rec.recordID.recordName == "profile")
        let back = try #require(ProfileRecordMapper.profile(from: rec))
        #expect(back.weightKg == 78)
        #expect(back.modifiedAt == p.modifiedAt)
    }
}
