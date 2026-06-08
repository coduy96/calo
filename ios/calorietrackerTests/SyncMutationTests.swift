import Testing
import Foundation
@testable import calorietracker

struct SyncMutationTests {
    @Test func recordNameNamespacesByKind() {
        let id = UUID()
        #expect(SyncRecordKind.food.recordName(for: id) == "food_\(id.uuidString)")
        #expect(SyncRecordKind.favorite.recordName(for: id) == "fav_\(id.uuidString)")
        #expect(SyncRecordKind.weight.recordName(for: id) == "weight_\(id.uuidString)")
    }
    @Test func parsesKindAndIDFromRecordName() {
        let id = UUID()
        let parsed = SyncRecordKind.parse(recordName: "bodyfat_\(id.uuidString)")
        #expect(parsed?.kind == .bodyFat)
        #expect(parsed?.id == id)
    }
    @Test func profileHasFixedRecordName() {
        #expect(SyncRecordKind.profile.fixedRecordName == "profile")
    }
}
