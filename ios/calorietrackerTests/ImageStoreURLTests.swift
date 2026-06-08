import Testing
import Foundation
@testable import calorietracker

@Suite(.serialized)
struct ImageStoreURLTests {
    @Test func foodImageURLRoundTrips() throws {
        let id = UUID()
        let bytes = Data([0xFF, 0xD8, 0xFF, 0xD9])
        let name = try #require(FoodImageStore.shared.store(data: bytes, for: id))
        let url = try #require(FoodImageStore.shared.fileURL(for: name))
        #expect(FileManager.default.fileExists(atPath: url.path))
        FoodImageStore.shared.delete(filename: name)
    }
    @Test func missingFileURLReturnsPathButNoFile() throws {
        let url = try #require(FoodImageStore.shared.fileURL(for: "does-not-exist.jpg"))
        #expect(!FileManager.default.fileExists(atPath: url.path))
    }
    @Test func weightPhotoURLRoundTrips() throws {
        let id = UUID()
        let bytes = Data([0xFF, 0xD8, 0xFF, 0xD9])
        let name = try #require(WeightPhotoStore.shared.store(data: bytes, for: id))
        let url = try #require(WeightPhotoStore.shared.fileURL(for: name))
        #expect(FileManager.default.fileExists(atPath: url.path))
        WeightPhotoStore.shared.delete(filename: name)
    }
}
