#if DEBUG
import Foundation

/// One-shot launch-time data faker so App Store / marketing screenshots have
/// a believable, attractive history of food, weight, and AI Coach activity
/// without needing to babysit the simulator for weeks. Triggered by passing
/// `--seed-mock-data` to the app on launch (Edit Scheme → Run → Arguments).
///
/// The seeder writes directly to UserDefaults under the same keys the live
/// stores read on init, then `calorietrackerApp.init()` calls `reloadFromDisk`
/// on each store so the in-memory @State instances pick up the freshly
/// seeded data without an app relaunch.
///
/// Wrapped entirely in `#if DEBUG` so none of this ships in Release builds.
enum MockDataSeeder {
    static let flag = "--seed-mock-data"

    static var isRequested: Bool {
        CommandLine.arguments.contains(flag)
    }

    /// Idempotent: rewrites the same dataset every launch the flag is passed,
    /// so iterating on screenshot copy is just edit + rebuild. Skips silently
    /// when the flag is absent.
    static func seedIfRequested() {
        guard isRequested else { return }
        let defaults = UserDefaults.standard
        defaults.set(true, forKey: "hasCompletedOnboarding")
        defaults.set(true, forKey: "aiAnalysisConsentGiven")
        // Don't surface notification permission UI right after seeding — it
        // would block the screenshot with a system alert.
        defaults.set(false, forKey: "notificationsEnabled")
        // Default "Calories / Protein / Carbs" trio on Home, no optional
        // nutrient goal overrides — keeps the Home rings looking clean.
        defaults.removeObject(forKey: "homeTopNutrients")
        defaults.removeObject(forKey: "optionalNutrientGoals")

        let profile = mockProfile()
        if let data = try? JSONEncoder().encode(profile) {
            defaults.set(data, forKey: "userProfile")
        }

        encodeAndStore(mockFoodEntries(), key: "foodEntries")
        encodeAndStore(mockFavorites(), key: "favoriteFoodEntries")
        encodeAndStore(mockWeightEntries(profile: profile), key: "weightEntries")
        encodeAndStore(mockBodyFatEntries(), key: "bodyFatEntries")
        encodeAndStore(mockChatThreads(), key: "coachChatThreads")
    }

    private static func encodeAndStore<T: Encodable>(_ value: T, key: String) {
        guard let data = try? JSONEncoder().encode(value) else { return }
        UserDefaults.standard.set(data, forKey: key)
    }

    // MARK: - Profile

    /// 28F, 165 cm, 64.2 kg → 60 kg goal, moderate activity, 24% body fat.
    /// Calories goal lands at ~1680 kcal which gives the Home ring room to
    /// show meaningful progress.
    private static func mockProfile() -> UserProfile {
        let calendar = Calendar.current
        let birthday = calendar.date(from: DateComponents(year: 1997, month: 6, day: 14))
            ?? Date().addingTimeInterval(-28 * 365 * 86_400)
        return UserProfile(
            name: "Alex",
            gender: .female,
            birthday: birthday,
            heightCm: 165,
            weightKg: 64.2,
            activityLevel: .moderate,
            goal: .lose,
            bodyFatPercentage: 0.24,
            goalBodyFatPercentage: 0.20,
            useBodyFatInBMR: true,
            weeklyChangeKg: 0.4,
            goalWeightKg: 60,
            customCalories: nil,
            customProtein: nil,
            customFat: nil,
            customCarbs: nil
        )
    }

    // MARK: - Food log

    /// Today (~91% logged so the Home ring looks near-complete) plus the
    /// trailing 13 days at 3–4 entries each, varied across the menu palette
    /// below to keep the Progress charts interesting.
    private static func mockFoodEntries() -> [FoodEntry] {
        var entries: [FoodEntry] = []
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())

        // Today — leave one snack slot un-logged so the day reads as "in
        // progress" and the Add Food affordances feel needed.
        entries.append(contentsOf: makeDay(
            startOfDay: startOfToday,
            picks: [(.breakfast, breakfasts[2], 8, 5),  // Eggs & Toast 8:05
                    (.lunch, lunches[6], 12, 35),       // Poke Bowl 12:35
                    (.snack, snacks[0], 15, 20),        // Apple + almond butter 15:20
                    (.dinner, dinners[0], 19, 10)]      // Grilled Salmon 19:10
        ))

        // Trailing 13 days, rotating menu so charts have real variance.
        // We seed `daysAgo = 1...13` so today is the freshest log.
        for daysAgo in 1...13 {
            guard let dayStart = calendar.date(byAdding: .day, value: -daysAgo, to: startOfToday) else { continue }
            let picks: [(MealType, MockMeal, Int, Int)]
            switch daysAgo % 7 {
            case 0:
                picks = [(.breakfast, breakfasts[0], 8, 15),
                         (.lunch, lunches[0], 12, 50),
                         (.snack, snacks[2], 16, 0),
                         (.dinner, dinners[1], 19, 30)]
            case 1:
                picks = [(.breakfast, breakfasts[4], 7, 45),
                         (.lunch, lunches[2], 13, 10),
                         (.dinner, dinners[3], 18, 50)]
            case 2:
                picks = [(.breakfast, breakfasts[6], 8, 30),
                         (.lunch, lunches[5], 12, 20),
                         (.snack, snacks[5], 15, 30),
                         (.dinner, dinners[2], 19, 45)]
            case 3:
                picks = [(.breakfast, breakfasts[1], 8, 0),
                         (.lunch, lunches[3], 13, 0),
                         (.snack, snacks[3], 16, 15),
                         (.dinner, dinners[4], 19, 20)]
            case 4:
                picks = [(.breakfast, breakfasts[5], 9, 10),
                         (.lunch, lunches[4], 12, 45),
                         (.snack, snacks[6], 15, 45),
                         (.dinner, dinners[5], 20, 0)]
            case 5:
                picks = [(.breakfast, breakfasts[3], 8, 20),
                         (.lunch, lunches[1], 12, 30),
                         (.dinner, dinners[6], 19, 15)]
            default:
                picks = [(.breakfast, breakfasts[2], 8, 10),
                         (.lunch, lunches[6], 13, 0),
                         (.snack, snacks[1], 16, 0),
                         (.dinner, dinners[0], 19, 0)]
            }
            entries.append(contentsOf: makeDay(startOfDay: dayStart, picks: picks))
        }

        return entries
    }

    private static func makeDay(startOfDay: Date, picks: [(MealType, MockMeal, Int, Int)]) -> [FoodEntry] {
        picks.map { meal, food, hour, minute in
            food.entry(timestamp: startOfDay.addingTimeInterval(Double(hour * 3600 + minute * 60)), mealType: meal)
        }
    }

    // MARK: - Favorites

    private static func mockFavorites() -> [FoodEntry] {
        let now = Date()
        // Favorites don't show a meal context in the saved-meals sheet, so
        // mealType doesn't matter; pick the closest cue for each.
        return [
            breakfasts[0].entry(timestamp: now, mealType: .breakfast),
            breakfasts[6].entry(timestamp: now, mealType: .breakfast),
            lunches[0].entry(timestamp: now, mealType: .lunch),
            lunches[6].entry(timestamp: now, mealType: .lunch),
            dinners[0].entry(timestamp: now, mealType: .dinner),
            snacks[5].entry(timestamp: now, mealType: .snack),
        ]
    }

    // MARK: - Weight history

    /// 60 days of weight, trending from ~68.4 kg → today's profile weight,
    /// with day-to-day noise so the chart line has texture instead of a
    /// straight ramp. Dates are placed at 8 AM in the user's calendar to
    /// avoid "future-time" cosmetic surprises.
    private static func mockWeightEntries(profile: UserProfile) -> [WeightEntry] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let target = profile.weightKg
        let start: Double = 68.4
        let days = 60

        // Reproducible LCG so every screenshot run gets the same line.
        var rng = SeededLCG(seed: 0xC0FFEE)
        var entries: [WeightEntry] = []
        for offset in stride(from: days, through: 0, by: -1) {
            let progress = Double(days - offset) / Double(days)
            let trend = start + (target - start) * progress
            // ±0.35 kg jitter so the line breathes; tighter near today so the
            // "current" reading lands exactly on `target`.
            let jitterRange = offset == 0 ? 0 : 0.35
            let jitter = (rng.nextUnitInterval() - 0.5) * 2 * jitterRange
            let weight = (trend + jitter * 0.7) // dampen so spikes feel realistic
            guard let date = calendar.date(byAdding: .day, value: -offset, to: startOfToday) else { continue }
            let stamped = date.addingTimeInterval(8 * 3600) // 8 AM
            entries.append(WeightEntry(date: stamped, weightKg: roundedHalf(weight)))
        }
        return entries
    }

    // MARK: - Body fat history

    /// 12 readings over 60 days (about one every five days, like a real
    /// home-scale cadence), trending 27.8% → 24%.
    private static func mockBodyFatEntries() -> [BodyFatEntry] {
        let calendar = Calendar.current
        let startOfToday = calendar.startOfDay(for: Date())
        let start = 0.278
        let end = 0.24
        let count = 12
        var rng = SeededLCG(seed: 0xBADBF7)
        var entries: [BodyFatEntry] = []
        for i in 0..<count {
            let daysAgo = (count - 1 - i) * 5
            let progress = Double(i) / Double(count - 1)
            let trend = start + (end - start) * progress
            let jitter = (rng.nextUnitInterval() - 0.5) * 2 * 0.006
            let value = (i == count - 1) ? end : trend + jitter
            guard let date = calendar.date(byAdding: .day, value: -daysAgo, to: startOfToday) else { continue }
            let stamped = date.addingTimeInterval(8 * 3600 + 15 * 60)
            entries.append(BodyFatEntry(date: stamped, bodyFatFraction: round(value * 10000) / 10000))
        }
        return entries
    }

    // MARK: - AI Coach threads

    private static func mockChatThreads() -> [ChatThread] {
        let now = Date()
        let calendar = Calendar.current

        let thread1Date = calendar.date(byAdding: .day, value: -6, to: now) ?? now
        let thread1 = ChatThread(
            title: "How can I hit my protein goal?",
            messages: [
                ChatMessage(role: .user, content: "I keep falling short of my protein target. Any practical tips?", timestamp: thread1Date),
                ChatMessage(role: .assistant, content: """
                    A few moves that consistently help:

                    1. **Anchor every meal with a 30 g+ protein source.** Greek yogurt, eggs, chicken, tofu, cottage cheese, whey — pick one per plate.
                    2. **Front-load breakfast.** A protein-rich first meal (e.g. eggs + Greek yogurt) takes pressure off dinner.
                    3. **Keep an emergency snack.** A scoop of whey, jerky, or a hard-boiled egg saves you on busy days.

                    You're averaging around 95 g lately on a 115 g goal — adding one protein-forward snack would close that gap.
                    """, timestamp: thread1Date.addingTimeInterval(30)),
                ChatMessage(role: .user, content: "Love the Greek yogurt idea. What flavor combos do you suggest?", timestamp: thread1Date.addingTimeInterval(180)),
                ChatMessage(role: .assistant, content: """
                    Try one of these — each lands around 250–300 kcal and 20+ g protein:

                    - Plain Greek yogurt + frozen berries + a drizzle of honey + crushed walnuts
                    - Vanilla Greek yogurt + sliced banana + a spoon of peanut butter + cinnamon
                    - Plain Greek yogurt + diced apple + granola + cardamom

                    Stir, don't layer — keeps every spoonful balanced.
                    """, timestamp: thread1Date.addingTimeInterval(220)),
            ],
            createdAt: thread1Date,
            updatedAt: thread1Date.addingTimeInterval(220)
        )

        let thread2Date = calendar.date(byAdding: .day, value: -3, to: now) ?? now
        let thread2 = ChatThread(
            title: "Best post-workout meal under 500 kcal?",
            messages: [
                ChatMessage(role: .user, content: "I just finished a 45-minute strength session. What should I eat in the next hour?", timestamp: thread2Date),
                ChatMessage(role: .assistant, content: """
                    For recovery in under 500 kcal, aim for **30 g protein + 50–60 g carbs + minimal fat** so it digests fast:

                    - Grilled chicken (120 g) + jasmine rice (¾ cup cooked) + steamed broccoli — ~470 kcal
                    - Greek yogurt bowl (200 g) + 1 banana + 30 g granola — ~420 kcal
                    - Tuna wrap on a whole-wheat tortilla + small apple — ~460 kcal

                    Hydrate alongside — the meal does more when you're not running low on fluids.
                    """, timestamp: thread2Date.addingTimeInterval(45)),
            ],
            createdAt: thread2Date,
            updatedAt: thread2Date.addingTimeInterval(45)
        )

        let thread3Date = calendar.date(byAdding: .day, value: -1, to: now) ?? now
        let thread3 = ChatThread(
            title: "Am I on track for my goal weight?",
            messages: [
                ChatMessage(role: .user, content: "Quick check — am I on pace for 60 kg?", timestamp: thread3Date),
                ChatMessage(role: .assistant, content: """
                    Looking at the last 30 days:

                    - **Weight trend:** down ~1.6 kg (from 65.8 to 64.2). That's about 0.4 kg/week — right on your target rate.
                    - **Body fat:** 25.4% → 24.0%, a clean drop alongside the weight.
                    - **Calories:** averaging 1,610/day against a 1,680 goal — slight deficit headroom.
                    - **Protein:** averaging 102 g/day. Closer to 115 g would lock in more lean mass during the cut.

                    Net: yes, you're on track. Bump protein, keep current activity, and you should hit 60 kg in roughly 10 weeks.
                    """, timestamp: thread3Date.addingTimeInterval(60)),
                ChatMessage(role: .user, content: "Perfect. What's one thing I should focus on this week?", timestamp: thread3Date.addingTimeInterval(300)),
                ChatMessage(role: .assistant, content: "Add 20 g of protein to your afternoon snack — that one swap likely closes the protein gap without adding meaningful calories.", timestamp: thread3Date.addingTimeInterval(340)),
            ],
            createdAt: thread3Date,
            updatedAt: thread3Date.addingTimeInterval(340)
        )

        return [thread1, thread2, thread3]
    }

    // MARK: - Helpers

    private static func roundedHalf(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }

    /// Linear congruential generator with a fixed seed so the seeded data is
    /// byte-identical across runs of the same build. Avoids pulling in
    /// SystemRandomNumberGenerator's non-determinism.
    private struct SeededLCG {
        private var state: UInt64
        init(seed: UInt64) { self.state = seed | 1 }
        mutating func next() -> UInt64 {
            state = state &* 6364136223846793005 &+ 1442695040888963407
            return state
        }
        mutating func nextUnitInterval() -> Double {
            Double(next() >> 11) / Double(1 << 53)
        }
    }
}

// MARK: - Mock meal palette

private struct MockMeal {
    let name: String
    let emoji: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fat: Int
    let sugar: Double?
    let fiber: Double?
    let sodium: Double?
    let servingGrams: Double
    let servingUnit: String

    func entry(timestamp: Date, mealType: MealType) -> FoodEntry {
        FoodEntry(
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fat: fat,
            timestamp: timestamp,
            imageData: nil,
            imageFilename: nil,
            emoji: emoji,
            source: .snapFood,
            mealType: mealType,
            sugar: sugar,
            addedSugar: nil,
            fiber: fiber,
            saturatedFat: nil,
            monounsaturatedFat: nil,
            polyunsaturatedFat: nil,
            cholesterol: nil,
            sodium: sodium,
            potassium: nil,
            servingSizeGrams: servingGrams,
            servingUnitOptions: [ServingUnitOption(unit: servingUnit, gramsPerUnit: servingGrams, quantity: 1)],
            selectedServingUnit: servingUnit,
            selectedServingQuantity: 1
        )
    }
}

private let breakfasts: [MockMeal] = [
    MockMeal(name: "Greek Yogurt Parfait", emoji: "🥣", calories: 320, protein: 22, carbs: 38, fat: 9, sugar: 18, fiber: 4, sodium: 95, servingGrams: 280, servingUnit: "bowl"),
    MockMeal(name: "Avocado Toast", emoji: "🥑", calories: 380, protein: 12, carbs: 42, fat: 18, sugar: 4, fiber: 9, sodium: 420, servingGrams: 220, servingUnit: "plate"),
    MockMeal(name: "Eggs & Sourdough", emoji: "🍳", calories: 410, protein: 24, carbs: 34, fat: 18, sugar: 3, fiber: 4, sodium: 510, servingGrams: 260, servingUnit: "plate"),
    MockMeal(name: "Protein Pancakes", emoji: "🥞", calories: 450, protein: 28, carbs: 52, fat: 12, sugar: 14, fiber: 5, sodium: 380, servingGrams: 240, servingUnit: "stack"),
    MockMeal(name: "Berry Smoothie Bowl", emoji: "🫐", calories: 340, protein: 22, carbs: 48, fat: 6, sugar: 24, fiber: 8, sodium: 110, servingGrams: 330, servingUnit: "bowl"),
    MockMeal(name: "Bagel with Cream Cheese", emoji: "🥯", calories: 420, protein: 14, carbs: 56, fat: 14, sugar: 8, fiber: 3, sodium: 620, servingGrams: 180, servingUnit: "bagel"),
    MockMeal(name: "Overnight Oats", emoji: "🌾", calories: 380, protein: 16, carbs: 56, fat: 9, sugar: 16, fiber: 8, sodium: 95, servingGrams: 320, servingUnit: "jar"),
]

private let lunches: [MockMeal] = [
    MockMeal(name: "Grilled Chicken Salad", emoji: "🥗", calories: 425, protein: 38, carbs: 18, fat: 22, sugar: 6, fiber: 6, sodium: 540, servingGrams: 360, servingUnit: "bowl"),
    MockMeal(name: "Turkey Avocado Wrap", emoji: "🌯", calories: 510, protein: 32, carbs: 48, fat: 18, sugar: 5, fiber: 7, sodium: 720, servingGrams: 300, servingUnit: "wrap"),
    MockMeal(name: "Chicken Burrito Bowl", emoji: "🍲", calories: 620, protein: 42, carbs: 68, fat: 18, sugar: 6, fiber: 9, sodium: 880, servingGrams: 420, servingUnit: "bowl"),
    MockMeal(name: "Salmon Sushi (8 pcs)", emoji: "🍣", calories: 450, protein: 22, carbs: 56, fat: 14, sugar: 8, fiber: 3, sodium: 760, servingGrams: 240, servingUnit: "roll set"),
    MockMeal(name: "Falafel Pita", emoji: "🥙", calories: 540, protein: 18, carbs: 68, fat: 22, sugar: 6, fiber: 10, sodium: 690, servingGrams: 320, servingUnit: "pita"),
    MockMeal(name: "Pesto Chicken Pasta", emoji: "🍝", calories: 580, protein: 35, carbs: 62, fat: 19, sugar: 5, fiber: 5, sodium: 640, servingGrams: 380, servingUnit: "bowl"),
    MockMeal(name: "Tuna Poke Bowl", emoji: "🍱", calories: 520, protein: 36, carbs: 54, fat: 16, sugar: 8, fiber: 6, sodium: 820, servingGrams: 400, servingUnit: "bowl"),
]

private let dinners: [MockMeal] = [
    MockMeal(name: "Grilled Salmon & Veggies", emoji: "🐟", calories: 480, protein: 38, carbs: 22, fat: 24, sugar: 6, fiber: 6, sodium: 460, servingGrams: 360, servingUnit: "plate"),
    MockMeal(name: "Roast Chicken & Rice", emoji: "🍗", calories: 560, protein: 42, carbs: 58, fat: 14, sugar: 3, fiber: 4, sodium: 520, servingGrams: 380, servingUnit: "plate"),
    MockMeal(name: "Steak with Sweet Potato", emoji: "🥩", calories: 620, protein: 48, carbs: 42, fat: 26, sugar: 9, fiber: 6, sodium: 580, servingGrams: 400, servingUnit: "plate"),
    MockMeal(name: "Shrimp Stir-fry", emoji: "🍤", calories: 420, protein: 32, carbs: 38, fat: 14, sugar: 8, fiber: 5, sodium: 780, servingGrams: 340, servingUnit: "bowl"),
    MockMeal(name: "Veggie Pizza (2 slices)", emoji: "🍕", calories: 540, protein: 22, carbs: 64, fat: 18, sugar: 6, fiber: 5, sodium: 920, servingGrams: 260, servingUnit: "slices"),
    MockMeal(name: "Chicken Curry & Rice", emoji: "🍛", calories: 590, protein: 36, carbs: 64, fat: 18, sugar: 7, fiber: 6, sodium: 720, servingGrams: 420, servingUnit: "plate"),
    MockMeal(name: "Chicken Tacos (3)", emoji: "🌮", calories: 480, protein: 32, carbs: 42, fat: 18, sugar: 4, fiber: 6, sodium: 650, servingGrams: 320, servingUnit: "tacos"),
]

private let snacks: [MockMeal] = [
    MockMeal(name: "Apple & Almond Butter", emoji: "🍎", calories: 215, protein: 6, carbs: 22, fat: 13, sugar: 16, fiber: 5, sodium: 65, servingGrams: 180, servingUnit: "serving"),
    MockMeal(name: "Mixed Nuts", emoji: "🥜", calories: 180, protein: 6, carbs: 8, fat: 16, sugar: 2, fiber: 3, sodium: 110, servingGrams: 30, servingUnit: "handful"),
    MockMeal(name: "Carrots & Hummus", emoji: "🥕", calories: 140, protein: 5, carbs: 16, fat: 7, sugar: 6, fiber: 5, sodium: 220, servingGrams: 140, servingUnit: "serving"),
    MockMeal(name: "Air-popped Popcorn", emoji: "🍿", calories: 110, protein: 4, carbs: 22, fat: 1, sugar: 0, fiber: 4, sodium: 95, servingGrams: 30, servingUnit: "bowl"),
    MockMeal(name: "Dark Chocolate Square", emoji: "🍫", calories: 90, protein: 1, carbs: 9, fat: 6, sugar: 6, fiber: 1, sodium: 5, servingGrams: 20, servingUnit: "square"),
    MockMeal(name: "Vanilla Protein Shake", emoji: "🥤", calories: 160, protein: 25, carbs: 8, fat: 3, sugar: 4, fiber: 1, sodium: 180, servingGrams: 350, servingUnit: "shake"),
    MockMeal(name: "Strawberry Yogurt Cup", emoji: "🍓", calories: 130, protein: 14, carbs: 12, fat: 2, sugar: 10, fiber: 2, sodium: 60, servingGrams: 170, servingUnit: "cup"),
]
#endif
