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
            copy = String(localized: "Your BMI sits in the underweight range — a reference point, not a verdict.")
            tone = .caution
        case .healthy:
            copy = String(localized: "Your BMI is in the healthy range — a strong foundation to build on.")
            tone = .positive
        case .overweight:
            copy = String(localized: "Your BMI is in the overweight range — a starting point, not the whole story.")
            tone = .neutral
        case .obese:
            copy = String(localized: "Your BMI is in the obese range — small steady changes move it more than you'd think.")
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
            copy = String(localized: "Katch-McArdle with your \(bfPct)% body fat — more accurate than weight alone.")
        } else {
            copy = String(localized: "Mifflin-St Jeor — a solid baseline from your height, weight, and age.")
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
            interpretation: String(localized: "With your \(activityName) routine, this is what your body spends on an average day."),
            tone: .neutral
        )
    }

    private var dailyTargetCard: Card {
        let adj = profile.calorieAdjustment
        let copy: String
        if adj < 0 {
            copy = String(localized: "A \(abs(adj)) cal deficit — sustainable and built around your TDEE, not a crash plan.")
        } else if adj > 0 {
            copy = String(localized: "A \(adj) cal surplus — paired with protein, this fuels lean growth.")
        } else {
            copy = String(localized: "Right at maintenance — your job is consistency, not restriction.")
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
        var copy = String(localized: "You'll reach \(weightStr) around \(dateStr). Patience compounds.")
        if paceIsAggressive {
            copy += " " + String(localized: "This pace is on the ambitious end — listen to your body.")
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
            return String(localized: "Your BMI is already healthy. Think recomposition: hit your protein target, lift twice a week, and let the scale move slowly.")
        case (.lose, .obese, true):
            return String(localized: "You're motivated — channel it into the first four weeks. Slower than your slider says will stick longer than faster.")
        case (.lose, _, _):
            return String(localized: "Protein first, then everything else falls into place. Aim for \(profile.proteinGoal)g a day.")
        case (.gain, .underweight, _):
            return String(localized: "Frequent meals matter more than huge ones. Focus on recovery, sleep, and progressive lifts.")
        case (.gain, _, _):
            return String(localized: "Surplus plus strength training equals muscle, not just weight. Track protein religiously.")
        case (.maintain, _, _):
            return String(localized: "You don't need to do more — you need to do this, consistently. Showing up is the win.")
        }
    }

    private func caloriesString(_ value: Int) -> String {
        String(localized: "\(value) cal")
    }
}
