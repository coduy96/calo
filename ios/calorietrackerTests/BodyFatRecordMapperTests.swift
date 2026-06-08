import Testing
import Foundation
import CloudKit
@testable import calorietracker

struct BodyFatRecordMapperTests {
    private let zoneID = CKRecordZone.ID(zoneName: "VoidpenZone", ownerName: CKCurrentUserDefaultName)

    @Test func roundTrip() throws {
        let e = BodyFatEntry(
            date: Date(timeIntervalSince1970: 500),
            bodyFatFraction: 0.21,
            modifiedAt: Date(timeIntervalSince1970: 1_700_000_000)
        )
        let rec = BodyFatRecordMapper.record(from: e, zoneID: zoneID)
        #expect(rec.recordType == "BodyFatEntry")
        #expect(rec.recordID.recordName == "bodyfat_\(e.id.uuidString)")
        let back = try #require(BodyFatRecordMapper.bodyFatEntry(from: rec))
        #expect(back.id == e.id)
        #expect(back.bodyFatFraction == 0.21)
    }
}
