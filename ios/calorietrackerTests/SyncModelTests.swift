import Testing
import Foundation
@testable import calorietracker

// MARK: - 1.2 BodyFatEntry

struct BodyFatEntryModifiedAtTests {
    @Test func newEntryHasModifiedAt() {
        #expect(BodyFatEntry(bodyFatFraction: 0.2).modifiedAt != nil)
    }
    @Test func legacyDecodesToNil() throws {
        let legacy = """
        {"id":"\(UUID().uuidString)","date":\(Date().timeIntervalSinceReferenceDate),"bodyFatFraction":0.18}
        """.data(using: .utf8)!
        let e = try JSONDecoder().decode(BodyFatEntry.self, from: legacy)
        #expect(e.modifiedAt == nil)
        #expect(e.effectiveModifiedAt == .distantPast)
    }
}

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
