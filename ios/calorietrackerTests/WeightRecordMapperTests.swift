import Testing
import Foundation
import CloudKit
@testable import calorietracker

struct WeightRecordMapperTests {
    private let zoneID = CKRecordZone.ID(zoneName: "VoidpenZone", ownerName: CKCurrentUserDefaultName)

    @Test func roundTrip() throws {
        let stamp = Date(timeIntervalSince1970: 1_700_000_000)
        let e = WeightEntry(date: Date(timeIntervalSince1970: 1000), weightKg: 73.2, modifiedAt: stamp)
        let rec = WeightRecordMapper.record(from: e, zoneID: zoneID)
        #expect(rec.recordType == "WeightEntry")
        #expect(rec.recordID.recordName == "weight_\(e.id.uuidString)")
        let back = try #require(WeightRecordMapper.weightEntry(from: rec))
        #expect(back.id == e.id)
        #expect(back.weightKg == 73.2)
        #expect(back.modifiedAt == stamp)
    }
}
