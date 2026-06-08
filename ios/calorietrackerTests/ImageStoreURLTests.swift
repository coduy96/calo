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
    @Test func missingFileURLReturnsPathButNoFile() {
        let url = FoodImageStore.shared.fileURL(for: "does-not-exist.jpg")
        if let url { #expect(!FileManager.default.fileExists(atPath: url.path)) }
    }
}
