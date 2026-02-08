import Foundation

enum FoodSource: String, Codable {
    case snapFood
    case nutritionLabel
    case textInput
}

enum MealType: String, Codable, CaseIterable {
    case breakfast
    case lunch
    case dinner
    case snack
    case other

    var displayName: String {
        switch self {
        case .breakfast: "Breakfast"
        case .lunch: "Lunch"
        case .dinner: "Dinner"
        case .snack: "Snack"
        case .other: "Other"
        }
    }

    var icon: String {
        switch self {
        case .breakfast: "sunrise.fill"
        case .lunch: "sun.max.fill"
        case .dinner: "moon.fill"
        case .snack: "cup.and.saucer.fill"
        case .other: "fork.knife"
        }
    }
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
    var mealType: MealType

    init(
        id: UUID = UUID(),
        name: String,
        calories: Int,
        protein: Int,
        carbs: Int,
        fat: Int,
        timestamp: Date = Date(),
        imageData: Data? = nil,
        source: FoodSource,
        mealType: MealType = .other
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
        self.mealType = mealType
    }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        name = try container.decode(String.self, forKey: .name)
        calories = try container.decode(Int.self, forKey: .calories)
        protein = try container.decode(Int.self, forKey: .protein)
        carbs = try container.decode(Int.self, forKey: .carbs)
        fat = try container.decode(Int.self, forKey: .fat)
        timestamp = try container.decode(Date.self, forKey: .timestamp)
        imageData = try container.decodeIfPresent(Data.self, forKey: .imageData)
        source = try container.decode(FoodSource.self, forKey: .source)
        mealType = try container.decodeIfPresent(MealType.self, forKey: .mealType) ?? .other
    }

    var timeString: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "h:mma"
        return formatter.string(from: timestamp).lowercased()
    }
}
