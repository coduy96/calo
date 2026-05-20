import Foundation

struct HealthInsights {
    let profile: UserProfile

    enum BMICategory {
        case underweight, healthy, overweight, obese
    }

    enum Tone {
        case neutral, positive, caution
    }

    struct Card: Identifiable {
        let id: String
        let icon: String
        let title: String
        let value: String
        let interpretation: String
        let tone: Tone
    }

    var bmi: Double {
        profile.weightKg / pow(profile.heightCm / 100.0, 2)
    }

    var bmiCategory: BMICategory {
        switch bmi {
        case ..<18.5: return .underweight
        case ..<25.0: return .healthy
        case ..<30.0: return .overweight
        default: return .obese
        }
    }

    var weeksToGoal: Int? {
        guard let target = profile.goalWeightKg,
              let pace = profile.weeklyChangeKg, pace > 0 else { return nil }
        let delta = abs(target - profile.weightKg)
        return max(1, Int((delta / pace).rounded()))
    }

    var goalDate: Date? {
        weeksToGoal.flatMap { Calendar.current.date(byAdding: .day, value: $0 * 7, to: .now) }
    }

    var paceIsAggressive: Bool {
        guard let pace = profile.weeklyChangeKg else { return false }
        return (pace / profile.weightKg) > 0.01
    }

    var cards: [Card] {
        var result: [Card] = [bmiCard, bmrCard, tdeeCard, dailyTargetCard]
        if let timeline = timelineCard { result.append(timeline) }
        return result
    }

    private var bmiCard: Card {
        let copy: String
        let tone: Tone
        switch bmiCategory {
        case .underweight:
            copy = String(localized: "BMI puts you below the healthy range. A starting line, not a label.")
            tone = .caution
        case .healthy:
            copy = String(localized: "BMI is in the healthy range. Strong place to build from.")
            tone = .positive
        case .overweight:
            copy = String(localized: "BMI reads overweight. It misses muscle and frame — but it's a fair signal.")
            tone = .neutral
        case .obese:
            copy = String(localized: "BMI reads obese. Small, steady moves shift it faster than you'd guess.")
            tone = .neutral
        }
        return Card(
            id: "bmi",
            icon: "figure",
            title: String(localized: "Body Mass Index"),
            value: String(format: "%.1f", bmi),
            interpretation: copy,
            tone: tone
        )
    }

    private var bmrCard: Card {
        let copy: String
        if profile.usesBodyFatForBMR, let bf = profile.bodyFatPercentage {
            let bfPct = Int((bf * 100).rounded())
            copy = String(localized: "Katch–McArdle, using your \(bfPct)% body fat. Sharper than weight alone.")
        } else {
            copy = String(localized: "Mifflin–St Jeor — the cleanest estimate from height, weight, and age.")
        }
        return Card(
            id: "bmr",
            icon: "flame.fill",
            title: String(localized: "Resting Burn"),
            value: caloriesString(Int(profile.bmr)),
            interpretation: copy,
            tone: .neutral
        )
    }

    private var tdeeCard: Card {
        let activityName = profile.activityLevel.displayName.lowercased()
        return Card(
            id: "tdee",
            icon: "figure.walk",
            title: String(localized: "Daily Burn"),
            value: caloriesString(Int(profile.tdee)),
            interpretation: String(localized: "Your \(activityName) routine puts your daily spend right here."),
            tone: .neutral
        )
    }

    private var dailyTargetCard: Card {
        let adj = profile.calorieAdjustment
        let copy: String
        if adj < 0 {
            copy = String(localized: "A \(abs(adj)) cal deficit — anchored to your TDEE, not pulled out of a hat.")
        } else if adj > 0 {
            copy = String(localized: "A \(adj) cal surplus. Hit your protein and most of it becomes muscle.")
        } else {
            copy = String(localized: "Right at maintenance. Show up daily; the rest takes care of itself.")
        }
        return Card(
            id: "target",
            icon: "target",
            title: String(localized: "Your Daily Target"),
            value: caloriesString(profile.dailyCalories),
            interpretation: copy,
            tone: .positive
        )
    }

    private var timelineCard: Card? {
        guard profile.goal != .maintain,
              let weeks = weeksToGoal,
              let target = profile.goalWeightKg,
              let date = goalDate else { return nil }
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        let dateStr = formatter.string(from: date)
        let weightStr = String(format: "%.1f kg", target)
        var copy = String(localized: "You hit \(weightStr) around \(dateStr). The math is on your side if you stay in it.")
        if paceIsAggressive {
            copy += " " + String(localized: "Pace is on the steep end — back off if your sleep or mood drops.")
        }
        let weeksValue = String(localized: "\(weeks) weeks")
        return Card(
            id: "timeline",
            icon: "calendar",
            title: String(localized: "Timeline"),
            value: weeksValue,
            interpretation: copy,
            tone: paceIsAggressive ? .caution : .positive
        )
    }

    var primaryAdvice: String {
        switch (profile.goal, bmiCategory, paceIsAggressive) {
        case (.lose, .healthy, _):
            return String(localized: "Your BMI is already healthy — this is a recomp, not a cut. Hit protein, lift twice a week, ignore the scale for the first month.")
        case (.lose, .obese, true):
            return String(localized: "Spend your motivation on the first four weeks. Aim a notch slower than your slider — it sticks.")
        case (.lose, _, _):
            return String(localized: "Hit \(profile.proteinGoal)g protein every day. The rest sorts itself out.")
        case (.gain, .underweight, _):
            return String(localized: "Eat more often, not just more. Lift heavy. Sleep more than you think you need.")
        case (.gain, _, _):
            return String(localized: "Surplus plus lifting equals muscle. Without lifting it's just fat. Track protein.")
        case (.maintain, _, _):
            return String(localized: "You don't need a new plan. You need to run this one every day.")
        }
    }

    private func caloriesString(_ value: Int) -> String {
        String(localized: "\(value) cal")
    }
}
