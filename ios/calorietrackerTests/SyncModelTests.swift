import Testing
import Foundation
@testable import calorietracker

// MARK: - 1.1 WeightEntry

struct WeightEntryModifiedAtTests {
    @Test func newEntryHasModifiedAt() {
        let entry = WeightEntry(weightKg: 70)
        #expect(entry.modifiedAt != nil)
    }
    @Test func decodingLegacyDataWithoutModifiedAtYieldsNil() throws {
        let legacy = """
        {"id":"\(UUID().uuidString)","date":\(Date().timeIntervalSinceReferenceDate),"weightKg":72.5}
        """.data(using: .utf8)!
        let entry = try JSONDecoder().decode(WeightEntry.self, from: legacy)
        #expect(entry.modifiedAt == nil)
        #expect(entry.effectiveModifiedAt == .distantPast)
        #expect(entry.weightKg == 72.5)
    }
}
