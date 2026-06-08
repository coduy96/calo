import Testing
import Foundation
import CloudKit
@testable import calorietracker

@Suite(.serialized)
struct FoodRecordMapperTests {
    private let zoneID = CKRecordZone.ID(zoneName: "VoidpenZone", ownerName: CKCurrentUserDefaultName)

    @Test func roundTripCoreFields() throws {
        let stamp = Date(timeIntervalSince1970: 1_700_000_000)
        let e = FoodEntry(name: "Steak", calories: 500, protein: 40, carbs: 0, fat: 35,
                          source: .manual, mealType: .dinner, sugar: 1.5, sodium: 90, modifiedAt: stamp)
        let rec = FoodRecordMapper.record(from: e, kind: .food, zoneID: zoneID)
        #expect(rec.recordID.recordName == "food_\(e.id.uuidString)")
        #expect(rec.recordType == "FoodEntry")
        let back = try #require(FoodRecordMapper.foodEntry(from: rec))
        #expect(back.id == e.id)
        #expect(back.name == "Steak")
        #expect(back.calories == 500)
        #expect(back.sugar == 1.5)
        #expect(back.sodium == 90)
        #expect(back.mealType == .dinner)
        #expect(back.modifiedAt == stamp)
    }
    @Test func favoriteUsesFavPrefixAndType() {
        let e = FoodEntry(name: "F", calories: 1, protein: 0, carbs: 0, fat: 0, source: .manual)
        let rec = FoodRecordMapper.record(from: e, kind: .favorite, zoneID: zoneID)
        #expect(rec.recordID.recordName == "fav_\(e.id.uuidString)")
        #expect(rec.recordType == "FoodFavorite")
    }
    @Test func photoBecomesAssetAndDecodesBack() throws {
        let id = UUID()
        let jpeg = Data([0xFF, 0xD8, 0xFF, 0xE0, 0x00, 0x10, 0xFF, 0xD9])
        let filename = try #require(FoodImageStore.shared.store(data: jpeg, for: id))
        let e = FoodEntry(id: id, name: "WithPhoto", calories: 1, protein: 0, carbs: 0, fat: 0,
                          imageFilename: filename, source: .manual)
        let rec = FoodRecordMapper.record(from: e, kind: .food, zoneID: zoneID)
        #expect(rec["photo"] as? CKAsset != nil)
        FoodImageStore.shared.delete(filename: filename)   // simulate inbound on a fresh device
        let back = try #require(FoodRecordMapper.foodEntry(from: rec))
        #expect(back.imageFilename == filename)
        #expect(FoodImageStore.shared.load(filename: filename) == jpeg)
        FoodImageStore.shared.delete(filename: filename)
    }
}
