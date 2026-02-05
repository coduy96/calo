import Foundation

enum FoodSource: String, Codable {
    case snapFood
    case nutritionLabel
}

struct FoodEntry: Identifiable, Codable {
    let id: UUID
    var name: String
    var calories: Int
    var protein: Int
    var carbs: Int
    var fat: Int
    let timestamp: Date
    var imageData: Data?
    var source: FoodSource

    init(
        id: UUID = UUID(),
        name: String,
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int,
        timestamp: Date = Date(),
        imageData: Data? = nil,
        source: FoodSource
    ) {
        self.id = id
        self.name = name
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fat = fat
        self.timestamp = timestamp
        self.imageData = imageData
        self.source = source
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter.string(from: timestamp).lowercased()
    }
}
