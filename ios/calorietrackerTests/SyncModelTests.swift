import Testing
import Foundation
@testable import calorietracker

// MARK: - 1.3 FoodEntry

struct FoodEntryModifiedAtTests {
    @Test func newEntryHasModifiedAt() {
        let e = FoodEntry(name: "Apple", calories: 95, protein: 0, carbs: 25, fat: 0, source: .manual)
        #expect(e.modifiedAt != nil)
    }
    @Test func roundTripPreservesModifiedAt() throws {
        let stamp = Date(timeIntervalSince1970: 1_700_000_000)
        let e = FoodEntry(name: "Egg", calories: 70, protein: 6, carbs: 0, fat: 5, source: .manual, modifiedAt: stamp)
        let data = try JSONEncoder().encode(e)
        let decoded = try JSONDecoder().decode(FoodEntry.self, from: data)
        #expect(decoded.modifiedAt == stamp)
    }
    @Test func legacyFoodEntryDecodesToNilModifiedAt() throws {
        let id = UUID().uuidString
        let legacy = """
        {"id":"\(id)","name":"Toast","calories":100,"protein":3,"carbs":18,"fat":1,"timestamp":\(Date().timeIntervalSinceReferenceDate),"source":"manual","mealType":"breakfast"}
        """.data(using: .utf8)!
        let e = try JSONDecoder().decode(FoodEntry.self, from: legacy)
        #expect(e.modifiedAt == nil)
        #expect(e.effectiveModifiedAt == .distantPast)
    }
}

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
