import Testing
import Foundation
@testable import calorietracker

@Suite struct NutritionScoreTests {

    /// Builds a food whose per-serving values equal per-100g values (100 g serving).
    private func food(
        _ name: String,
        kcal: Int, protein: Int, carbs: Int, fat: Int,
        sugar: Double? = nil, addedSugar: Double? = nil, fiber: Double? = nil,
        satFat: Double? = nil, mono: Double? = nil, poly: Double? = nil,
        cholesterol: Double? = nil, sodium: Double? = nil, potassium: Double? = nil,
        grams: Double? = 100
    ) -> FoodEntry {
        FoodEntry(
            name: name, calories: kcal, protein: protein, carbs: carbs, fat: fat,
            source: .manual,
            sugar: sugar, addedSugar: addedSugar, fiber: fiber,
            saturatedFat: satFat, monounsaturatedFat: mono, polyunsaturatedFat: poly,
            cholesterol: cholesterol, sodium: sodium, potassium: potassium,
            servingSizeGrams: grams
        )
    }

    // MARK: Reference foods (the calibration fixture)

    private var salad: FoodEntry {
        food("Garden Salad", kcal: 50, protein: 2, carbs: 5, fat: 3,
             sugar: 2, fiber: 2, satFat: 0.5, mono: 1.5, poly: 0.8, sodium: 150, potassium: 300)
    }
    private var chicken: FoodEntry {
        food("Grilled Chicken Breast", kcal: 165, protein: 31, carbs: 0, fat: 4,
             sugar: 0, fiber: 0, satFat: 1.0, mono: 1.2, poly: 0.8, cholesterol: 85, sodium: 74, potassium: 256)
    }
    private var oats: FoodEntry {
        food("Rolled Oats", kcal: 389, protein: 17, carbs: 66, fat: 7,
             sugar: 1, fiber: 10.6, satFat: 1.2, mono: 2.2, poly: 2.5, sodium: 2, potassium: 429)
    }
    private var cola: FoodEntry {
        food("Cola", kcal: 42, protein: 0, carbs: 11, fat: 0,
             sugar: 10.6, addedSugar: 10.6, fiber: 0, satFat: 0, sodium: 4, potassium: 2)
    }
    private var fries: FoodEntry {
        food("French Fries", kcal: 312, protein: 3, carbs: 41, fat: 15,
             sugar: 0.3, fiber: 3.8, satFat: 2.3, mono: 3.5, poly: 8, sodium: 210, potassium: 579)
    }
    private var chocolate: FoodEntry {
        food("Chocolate Bar", kcal: 535, protein: 8, carbs: 59, fat: 30,
             sugar: 52, addedSugar: 50, fiber: 3.4, satFat: 18, mono: 9, poly: 1, cholesterol: 23, sodium: 79, potassium: 372)
    }

    @Test func saladScoresWell() {
        let s = NutritionScoreEngine.score(for: salad)
        #expect(s.value >= 65)              // B or better
        #expect(s.grade == .a || s.grade == .b)
        #expect(s.confidence == .full)
    }

    @Test func chickenScoresHigh() {
        let s = NutritionScoreEngine.score(for: chicken)
        #expect(s.value >= 65)
        #expect(s.positives.contains(.highProtein))
    }

    @Test func oatsScoreTopGrade() {
        let s = NutritionScoreEngine.score(for: oats)
        #expect(s.value >= 80)
        #expect(s.grade == .a)
        #expect(s.positives.contains(.highFiber))
    }

    @Test func colaScoresVeryPoor() {
        let s = NutritionScoreEngine.score(for: cola)
        #expect(s.grade == .e)
        #expect(s.negatives.contains(.highAddedSugar))
    }

    @Test func friesScorePoor() {
        let s = NutritionScoreEngine.score(for: fries)
        #expect(s.grade == .d)
    }

    @Test func chocolateScoresVeryPoor() {
        let s = NutritionScoreEngine.score(for: chocolate)
        #expect(s.grade == .e)
        #expect(s.negatives.contains(.highSaturatedFat))
        #expect(s.negatives.contains(.highSugar))
    }

    @Test func wholeFoodsOutrankJunk() {
        #expect(NutritionScoreEngine.score(for: oats).value > NutritionScoreEngine.score(for: fries).value)
        #expect(NutritionScoreEngine.score(for: salad).value > NutritionScoreEngine.score(for: cola).value)
        #expect(NutritionScoreEngine.score(for: chicken).value > NutritionScoreEngine.score(for: chocolate).value)
    }

    // MARK: Grade boundaries

    @Test func gradeCutoffs() {
        #expect(NutritionGrade(score: 100) == .a)
        #expect(NutritionGrade(score: 80) == .a)
        #expect(NutritionGrade(score: 79) == .b)
        #expect(NutritionGrade(score: 65) == .b)
        #expect(NutritionGrade(score: 64) == .c)
        #expect(NutritionGrade(score: 50) == .c)
        #expect(NutritionGrade(score: 49) == .d)
        #expect(NutritionGrade(score: 35) == .d)
        #expect(NutritionGrade(score: 34) == .e)
        #expect(NutritionGrade(score: 0) == .e)
    }

    // MARK: Confidence / graceful degradation

    @Test func macrosOnlyWithGramsIsLimited() {
        // Has serving grams but fewer than 2 needle-mover micros → limited.
        let s = NutritionScoreEngine.score(for: food("Mystery", kcal: 200, protein: 10, carbs: 20, fat: 8))
        #expect(s.confidence == .limited)
        #expect(s.value >= 0 && s.value <= 100)   // still produces a number
    }

    @Test func missingGramsIsLimited() {
        let s = NutritionScoreEngine.score(
            for: food("No Serving", kcal: 200, protein: 10, carbs: 20, fat: 8,
                      sugar: 5, fiber: 3, satFat: 2, sodium: 100, grams: nil)
        )
        #expect(s.confidence == .limited)
    }

    @Test func fullDataIsFullConfidence() {
        #expect(NutritionScoreEngine.score(for: salad).confidence == .full)
    }

    // MARK: Daily score

    @Test func emptyDayHasNoScore() {
        #expect(NutritionScoreEngine.dailyScore(for: []) == nil)
        // Zero-calorie entries also yield no score.
        #expect(NutritionScoreEngine.dailyScore(for: [food("Water", kcal: 0, protein: 0, carbs: 0, fat: 0)]) == nil)
    }

    @Test func dailyScoreIsCalorieWeightedBetweenFoods() {
        let day = NutritionScoreEngine.dailyScore(for: [oats, cola])
        #expect(day != nil)
        let low = NutritionScoreEngine.score(for: cola).value
        let high = NutritionScoreEngine.score(for: oats).value
        #expect(day!.value >= low && day!.value <= high)
    }

    @Test func dailyScoreSingleFoodMatchesPerFood() {
        let day = NutritionScoreEngine.dailyScore(for: [chicken])
        #expect(day?.value == NutritionScoreEngine.score(for: chicken).value)
    }
}
