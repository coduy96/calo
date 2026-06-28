import Foundation
import SwiftUI

/// A deterministic, on-device nutrition-quality score for a food (or a day of
/// food). Pure function of an existing `FoodEntry` — no AI/backend call, no
/// stored state. The score grades *quality*, not amount: it is normalized
/// per 100 g, so the same food gets the same grade regardless of serving size.
///
/// Honesty contract: nutrients we don't have are treated as neutral (never
/// penalized), and a food/day scored from too little data is flagged
/// `.limited` so the UI can say so rather than over-claim.
struct NutritionScore {
    let value: Int                       // 0...100
    let grade: NutritionGrade
    let confidence: Confidence
    let positives: [NutritionContributor]
    let negatives: [NutritionContributor]

    enum Confidence {
        case full
        case limited
    }

    var isLimited: Bool { confidence == .limited }
}

// MARK: - Grade

enum NutritionGrade: String, CaseIterable, Identifiable {
    case a = "A"
    case b = "B"
    case c = "C"
    case d = "D"
    case e = "E"

    var id: String { rawValue }

    /// Maps a 0–100 score to a letter grade. Cutoffs: A 80+, B 65+, C 50+, D 35+, E else.
    init(score: Int) {
        switch score {
        case 80...: self = .a
        case 65..<80: self = .b
        case 50..<65: self = .c
        case 35..<50: self = .d
        default: self = .e
        }
    }

    /// Letter shown in the badge. Not localized — it's a symbol.
    var letter: String { rawValue }

    var color: Color {
        switch self {
        case .a: Color(hex: 0x34C759) // green
        case .b: Color(hex: 0x9ACD32) // lime
        case .c: Color(hex: 0xFFCC00) // amber
        case .d: Color(hex: 0xFF9500) // orange
        case .e: Color(hex: 0xFF3B30) // red
        }
    }

    /// One-word quality summary (localized).
    var word: String {
        switch self {
        case .a: String(localized: "Excellent")
        case .b: String(localized: "Good")
        case .c: String(localized: "Fair")
        case .d: String(localized: "Poor")
        case .e: String(localized: "Very poor")
        }
    }
}

// MARK: - Contributors

/// A reason a food scored the way it did. Labels are static `String(localized:)`
/// literals (never interpolated) so the catalog/translators can reach them.
enum NutritionContributor: String, CaseIterable, Identifiable {
    // Positive
    case highProtein
    case highFiber
    case goodPotassium
    case healthyFats
    // Negative
    case highAddedSugar
    case highSugar
    case highSaturatedFat
    case highSodium
    case energyDense
    case highCholesterol

    var id: String { rawValue }

    var isPositive: Bool {
        switch self {
        case .highProtein, .highFiber, .goodPotassium, .healthyFats: true
        default: false
        }
    }

    var label: String {
        switch self {
        case .highProtein: String(localized: "High protein")
        case .highFiber: String(localized: "High fiber")
        case .goodPotassium: String(localized: "Good potassium")
        case .healthyFats: String(localized: "Healthy fats")
        case .highAddedSugar: String(localized: "High added sugar")
        case .highSugar: String(localized: "High sugar")
        case .highSaturatedFat: String(localized: "High saturated fat")
        case .highSodium: String(localized: "High sodium")
        case .energyDense: String(localized: "Energy dense")
        case .highCholesterol: String(localized: "High cholesterol")
        }
    }

    var iconName: String {
        switch self {
        case .highProtein: "fork.knife"
        case .highFiber: "leaf.fill"
        case .goodPotassium: "bolt.fill"
        case .healthyFats: "drop.fill"
        case .highAddedSugar: "plus.circle.fill"
        case .highSugar: "cube.fill"
        case .highSaturatedFat: "circle.lefthalf.filled"
        case .highSodium: "circle.grid.2x2.fill"
        case .energyDense: "flame.fill"
        case .highCholesterol: "heart.fill"
        }
    }
}

// MARK: - Engine

enum NutritionScoreEngine {

    /// Tunable coefficients. Kept in one place so the model can be re-balanced
    /// without hunting through the math. See `NutritionScoreTests` for the
    /// reference foods these are calibrated against.
    private enum K {
        static let base = 55.0
        static let netScale = 4.5

        // When serving grams are unknown, estimate mass from energy at a
        // typical mixed-food density (~1.5 kcal/g) so densities are still
        // computable. The result is always flagged `.limited`.
        static let fallbackKcalPerGram = 1.5

        // A contributor must move the score by at least this many points to be
        // worth surfacing in the breakdown.
        static let contributorThreshold = 1.5

        // A daily contributor must account for at least this share of the day's
        // calories to be surfaced.
        static let dailyContributorShare = 0.25
    }

    // MARK: Per-food

    static func score(for entry: FoodEntry) -> NutritionScore {
        let grams = entry.servingSizeGrams ?? 0
        let hasGrams = grams > 0
        // Fall back to an energy-derived mass when grams are missing.
        let effectiveGrams = hasGrams ? grams : max(Double(entry.calories) / K.fallbackKcalPerGram, 1)
        let k100 = 100 / effectiveGrams

        let kcal100 = Double(entry.calories) * k100
        let protein100 = Double(entry.protein) * k100
        let fat100 = Double(entry.fat) * k100
        let sugar100 = (entry.sugar ?? 0) * k100
        let addedSugar100 = (entry.addedSugar ?? 0) * k100
        let fiber100 = (entry.fiber ?? 0) * k100
        let satFat100 = (entry.saturatedFat ?? 0) * k100
        let mono100 = (entry.monounsaturatedFat ?? 0) * k100
        let poly100 = (entry.polyunsaturatedFat ?? 0) * k100
        let sodium100 = (entry.sodium ?? 0) * k100
        let potassium100 = (entry.potassium ?? 0) * k100
        let chol100 = (entry.cholesterol ?? 0) * k100

        // Negatives
        let energyPts = clamp((kcal100 - 40) / 70, 0, 7)
        var sugarPts = clamp((sugar100 - 4.5) / 4.5, 0, 9)
        var addedSugarPts = clamp(addedSugar100 / 6, 0, 6)
        let satFatPts = clamp(satFat100 / 1.0, 0, 10)
        let sodiumPts = clamp(sodium100 / 90, 0, 10)
        let cholPts = clamp(chol100 / 100, 0, 2)

        // Beverage correction: dilute sugary drinks are under-penalized per
        // 100 g. Detect "empty liquid calories" structurally (no fat, no fiber,
        // little protein, sugary, low energy density) so soda/juice get dinged
        // but milk (protein/fat) and fruit (fiber) never do.
        let totalFat100 = satFat100 + mono100 + poly100
        let isLikelyBeverage = totalFat100 < 0.5
            && fiber100 < 0.5
            && protein100 < 2
            && sugar100 > 5
            && kcal100 < 80
        if isLikelyBeverage {
            sugarPts *= 1.6
            addedSugarPts *= 1.6
        }

        // Positives
        let proteinPts = clamp((protein100 - 1.6) / 1.2, 0, 6)
        let fiberPts = clamp((fiber100 - 0.7) / 1.2, 0, 6)
        let potassiumPts = clamp(potassium100 / 250, 0, 2)
        // Unsaturated-fat reward is gated so oil can't rescue energy-dense food.
        let unsatRatio = (mono100 + poly100) / max(mono100 + poly100 + satFat100, 0.0001)
        let unsatPts = (fat100 >= 3 && kcal100 < 280) ? clamp(unsatRatio * 3, 0, 3) : 0

        // Whole-food nudge: water-rich, low-energy-density foods that also carry
        // some fiber or protein (vegetables, fruit, broth-based dishes). Gated by
        // a whole-food signal so it never rewards dilute empty-calorie liquids
        // like soda.
        let isWholeFood = fiber100 >= 1 || protein100 >= 3
        let lowEnergyPts = isWholeFood ? clamp((110 - kcal100) / 70, 0, 2.5) : 0

        let posSum = proteinPts + fiberPts + potassiumPts + unsatPts + lowEnergyPts
        let negSum = energyPts + sugarPts + addedSugarPts + satFatPts + sodiumPts + cholPts
        let net = posSum - negSum
        let value = Int(clamp((K.base + net * K.netScale).rounded(), 0, 100))

        // Contributors (anything that moved the score meaningfully)
        var positives: [(NutritionContributor, Double)] = []
        var negatives: [(NutritionContributor, Double)] = []
        func addPos(_ c: NutritionContributor, _ pts: Double) { if pts >= K.contributorThreshold { positives.append((c, pts)) } }
        func addNeg(_ c: NutritionContributor, _ pts: Double) { if pts >= K.contributorThreshold { negatives.append((c, pts)) } }
        addPos(.highProtein, proteinPts)
        addPos(.highFiber, fiberPts)
        addPos(.goodPotassium, potassiumPts)
        addPos(.healthyFats, unsatPts)
        addNeg(.highAddedSugar, addedSugarPts)
        addNeg(.highSugar, sugarPts)
        addNeg(.highSaturatedFat, satFatPts)
        addNeg(.highSodium, sodiumPts)
        addNeg(.energyDense, energyPts)
        addNeg(.highCholesterol, cholPts)

        let confidence = self.confidence(for: entry, hasGrams: hasGrams)

        return NutritionScore(
            value: value,
            grade: NutritionGrade(score: value),
            confidence: confidence,
            positives: positives.sorted { $0.1 > $1.1 }.map(\.0),
            negatives: negatives.sorted { $0.1 > $1.1 }.map(\.0)
        )
    }

    /// `.full` when serving grams are known AND at least two needle-moving
    /// micronutrients are present; otherwise `.limited`.
    private static func confidence(for entry: FoodEntry, hasGrams: Bool) -> NutritionScore.Confidence {
        guard hasGrams else { return .limited }
        let needleMovers = [entry.sugar, entry.fiber, entry.saturatedFat, entry.sodium]
        let present = needleMovers.compactMap { $0 }.count
        return present >= 2 ? .full : .limited
    }

    // MARK: Per-day

    /// Calorie-weighted average of the day's per-food scores. Returns nil for an
    /// empty day (no entries / no calories). Daily contributors are surfaced by
    /// calorie-weighted vote across the day's foods.
    static func dailyScore(for entries: [FoodEntry]) -> NutritionScore? {
        let totalKcal = entries.reduce(0) { $0 + $1.calories }
        guard totalKcal > 0 else { return nil }

        let scored: [(entry: FoodEntry, score: NutritionScore)] = entries.map { ($0, score(for: $0)) }

        var weightedSum = 0.0
        var limitedKcal = 0
        for item in scored {
            weightedSum += Double(item.score.value) * Double(item.entry.calories)
            if item.score.isLimited { limitedKcal += item.entry.calories }
        }
        let value = Int(clamp((weightedSum / Double(totalKcal)).rounded(), 0, 100))

        // Confidence: limited if more than 40% of the day's calories come from
        // limited-confidence foods.
        let confidence: NutritionScore.Confidence =
            (Double(limitedKcal) / Double(totalKcal) > 0.4) ? .limited : .full

        // Contributors: calorie-weighted vote.
        var posWeight: [NutritionContributor: Int] = [:]
        var negWeight: [NutritionContributor: Int] = [:]
        for item in scored {
            for c in item.score.positives { posWeight[c, default: 0] += item.entry.calories }
            for c in item.score.negatives { negWeight[c, default: 0] += item.entry.calories }
        }
        let cutoff = Double(totalKcal) * K.dailyContributorShare
        func top(_ weights: [NutritionContributor: Int]) -> [NutritionContributor] {
            weights
                .filter { Double($0.value) >= cutoff }
                .sorted { $0.value > $1.value }
                .prefix(3)
                .map(\.key)
        }

        return NutritionScore(
            value: value,
            grade: NutritionGrade(score: value),
            confidence: confidence,
            positives: top(posWeight),
            negatives: top(negWeight)
        )
    }

    // MARK: Helpers

    private static func clamp(_ x: Double, _ lo: Double, _ hi: Double) -> Double {
        min(max(x, lo), hi)
    }
}
