import Foundation

struct WeightEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    var weightKg: Double
    var photoFilename: String?

    init(id: UUID = UUID(), date: Date = .now, weightKg: Double, photoFilename: String? = nil) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.photoFilename = photoFilename
    }

    var weightLbs: Double {
        weightKg * 2.20462
    }
}
