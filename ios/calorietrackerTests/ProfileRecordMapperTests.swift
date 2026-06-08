import Testing
import Foundation
import CloudKit
@testable import calorietracker

struct ProfileRecordMapperTests {
    private let zoneID = CKRecordZone.ID(zoneName: "VoidpenZone", ownerName: CKCurrentUserDefaultName)

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
