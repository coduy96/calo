import Foundation

/// Vitamins & minerals tracked in addition to the core macros/micros. Stored on
/// `FoodEntry.micronutrients` keyed by `storageKey` so adding a new nutrient is
/// one enum case (plus a word in each AI prompt) rather than a field across the
/// whole Codable/sync/HealthKit surface. Mirrors `OptionalNutrient`.
enum Micronutrient: String, CaseIterable, Identifiable, Codable {
    case iron
    case calcium
    case vitaminC
    case vitaminD

    var id: String { rawValue }

    /// Key used in the AI JSON schema (snake_case, English — matched programmatically).
    var jsonKey: String {
        switch self {
        case .iron: "iron"
        case .calcium: "calcium"
        case .vitaminC: "vitamin_c"
        case .vitaminD: "vitamin_d"
        }
    }

    /// Key used in the `FoodEntry.micronutrients` dictionary and CloudKit blob.
    /// Encodes the unit so a future unit change is unambiguous.
    var storageKey: String {
        switch self {
        case .iron: "iron_mg"
        case .calcium: "calcium_mg"
        case .vitaminC: "vitamin_c_mg"
        case .vitaminD: "vitamin_d_mcg"
        }
    }

    var displayName: String {
        switch self {
        case .iron: String(localized: "Iron")
        case .calcium: String(localized: "Calcium")
        case .vitaminC: String(localized: "Vitamin C")
        case .vitaminD: String(localized: "Vitamin D")
        }
    }

    var unit: String {
        switch self {
        case .iron, .calcium, .vitaminC: "mg"
        case .vitaminD: "µg"
        }
    }

    var iconName: String {
        switch self {
        case .iron: "atom"
        case .calcium: "drop.fill"
        case .vitaminC: "leaf.fill"
        case .vitaminD: "sun.max.fill"
        }
    }

    /// Reasonable general-adult daily target (RDA-ish). All are target-style.
    var defaultGoal: Int {
        switch self {
        case .iron: 18       // mg
        case .calcium: 1_000 // mg
        case .vitaminC: 90   // mg
        case .vitaminD: 20   // µg
        }
    }

    /// Maps an AI JSON key (in either snake_case or storageKey form) to a case.
    init?(jsonKey: String) {
        if let match = Micronutrient.allCases.first(where: { $0.jsonKey == jsonKey || $0.storageKey == jsonKey }) {
            self = match
        } else {
            return nil
        }
    }

    // MARK: Open Food Facts

    /// Open Food Facts nutriment key (per-100g values, expressed in grams).
    var openFoodFactsKey: String {
        switch self {
        case .iron: "iron"
        case .calcium: "calcium"
        case .vitaminC: "vitamin-c"
        case .vitaminD: "vitamin-d"
        }
    }

    /// Factor to convert Open Food Facts grams into this nutrient's unit.
    var gramsToUnitFactor: Double {
        switch self {
        case .iron, .calcium, .vitaminC: 1_000      // g → mg
        case .vitaminD: 1_000_000                    // g → µg
        }
    }
}
