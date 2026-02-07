import Foundation

// MARK: - Enums

enum Gender: String, Codable, CaseIterable {
    case male, female, other

    var displayName: String {
        switch self {
        case .male: "Male"
        case .female: "Female"
        case .other: "Other"
        }
    }

    var icon: String {
        switch self {
        case .male: "figure.stand"
        case .female: "figure.stand.dress"
        case .other: "figure.wave"
        }
    }
}

enum ActivityLevel: String, Codable, CaseIterable {
    case sedentary    // 0-2 workouts/week
    case moderate     // 3-5 workouts/week
    case active       // 6+ workouts/week

    var displayName: String {
        switch self {
        case .sedentary: "Light"
        case .moderate: "Moderate"
        case .active: "Active"
        }
    }

    var subtitle: String {
        switch self {
        case .sedentary: "0–2 workouts / week"
        case .moderate: "3–5 workouts / week"
        case .active: "6+ workouts / week"
        }
    }

    var icon: String {
        switch self {
        case .sedentary: "figure.walk"
        case .moderate: "figure.run"
        case .active: "figure.highintensity.intervaltraining"
        }
    }

    var multiplier: Double {
        switch self {
        case .sedentary: 1.2
        case .moderate: 1.55
        case .active: 1.725
        }
    }
}

enum WeightGoal: String, Codable, CaseIterable {
    case lose, maintain, gain

    var displayName: String {
        switch self {
        case .lose: "Lose Weight"
        case .maintain: "Maintain"
        case .gain: "Gain Weight"
        }
    }

    var icon: String {
        switch self {
        case .lose: "arrow.down.right"
        case .maintain: "equal"
        case .gain: "arrow.up.right"
        }
    }

    var adjustment: Int {
        switch self {
        case .lose: -500
        case .maintain: 0
        case .gain: 500
        }
    }
}

// MARK: - User Profile

struct UserProfile: Codable {
    var gender: Gender
    var birthday: Date
    var heightCm: Double
    var weightKg: Double
    var activityLevel: ActivityLevel
    var goal: WeightGoal

    var age: Int {
        Calendar.current.dateComponents([.year], from: birthday, to: Date()).year ?? 25
    }

    var bmr: Double {
        let base = 10 * weightKg + 6.25 * heightCm - 5 * Double(age) - 161
        switch gender {
        case .male: return base + 166
        case .female, .other: return base
        }
    }

    var tdee: Double {
        bmr * activityLevel.multiplier
    }

    var dailyCalories: Int {
        max(1200, Int(tdee) + goal.adjustment)
    }

    var proteinGoal: Int {
        Int(Double(dailyCalories) * 0.30 / 4) // 4 cal per gram
    }

    var carbsGoal: Int {
        Int(Double(dailyCalories) * 0.45 / 4) // 4 cal per gram
    }

    var fatGoal: Int {
        Int(Double(dailyCalories) * 0.25 / 9) // 9 cal per gram
    }

    static let `default` = UserProfile(
        gender: .male,
        birthday: Calendar.current.date(byAdding: .year, value: -25, to: Date()) ?? Date(),
        heightCm: 175,
        weightKg: 70,
        activityLevel: .moderate,
        goal: .maintain
    )

    // MARK: - Persistence

    static func load() -> UserProfile? {
        guard let data = UserDefaults.standard.data(forKey: "userProfile"),
              let profile = try? JSONDecoder().decode(UserProfile.self, from: data)
        else { return nil }
        return profile
    }

    func save() {
        if let data = try? JSONEncoder().encode(self) {
            UserDefaults.standard.set(data, forKey: "userProfile")
        }
    }
}
