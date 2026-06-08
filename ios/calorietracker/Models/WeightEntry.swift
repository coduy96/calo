import Foundation

struct WeightEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    var weightKg: Double
    var photoFilename: String?
    var modifiedAt: Date?

    init(id: UUID = UUID(), date: Date = .now, weightKg: Double, photoFilename: String? = nil, modifiedAt: Date? = Date()) {
        self.id = id
        self.date = date
        self.weightKg = weightKg
        self.photoFilename = photoFilename
        self.modifiedAt = modifiedAt
    }

    var weightLbs: Double {
        weightKg * 2.20462
    }

    var effectiveModifiedAt: Date { modifiedAt ?? .distantPast }
}
