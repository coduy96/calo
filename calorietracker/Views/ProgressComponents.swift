import SwiftUI
import Charts

// MARK: - Time Range

enum TimeRange: String, CaseIterable {
    case week = "Week"
    case month = "Month"
    case allTime = "All Time"

    var days: Int? {
        switch self {
        case .week: 7
        case .month: 30
        case .allTime: nil
        }
    }

    func dateRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: .now).addingTimeInterval(86399)
        if let days {
            let start = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: .now))!
            return start...end
        }
        let distantStart = calendar.date(byAdding: .year, value: -10, to: .now)!
        return distantStart...end
    }
}

// MARK: - Weight Chart Section

struct WeightChartSection: View {
    let weightEntries: [WeightEntry]
    let goalWeightLbs: Double?
    let currentWeightLbs: Double?
    let onLogWeight: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Weight")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                Spacer()
                Button(action: onLogWeight) {
                    Label("Log Weight", systemImage: "plus.circle.fill")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(AppColors.calorie)
                }
            }

            if weightEntries.isEmpty {
                emptyState("Log your first weight to see trends")
            } else {
                // Current / Goal row
                HStack(spacing: 16) {
                    if let current = currentWeightLbs {
                        StatBadge(label: "Current", value: String(format: "%.1f lbs", current))
                    }
                    if let goal = goalWeightLbs {
                        StatBadge(label: "Goal", value: String(format: "%.1f lbs", goal))
                    }
                }

                Chart {
                    ForEach(weightEntries) { entry in
                        LineMark(
                            x: .value("Date", entry.date, unit: .day),
                            y: .value("Weight", entry.weightLbs)
                        )
                        .foregroundStyle(AppColors.calorie)
                        .interpolationMethod(.catmullRom)

                        AreaMark(
                            x: .value("Date", entry.date, unit: .day),
                            y: .value("Weight", entry.weightLbs)
                        )
                        .foregroundStyle(
                            LinearGradient(
                                colors: [AppColors.calorie.opacity(0.25), AppColors.calorie.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .interpolationMethod(.catmullRom)

                        PointMark(
                            x: .value("Date", entry.date, unit: .day),
                            y: .value("Weight", entry.weightLbs)
                        )
                        .foregroundStyle(AppColors.calorie)
                        .symbolSize(30)
                    }
                }
                .chartYScale(domain: weightYDomain)
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: xAxisStride)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .frame(height: 180)
            }
        }
        .padding()
        .background(AppColors.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var xAxisStride: Int {
        let count = weightEntries.count
        if count <= 7 { return 1 }
        if count <= 30 { return 5 }
        return 7
    }

    private var weightYDomain: ClosedRange<Double> {
        let weights = weightEntries.map { $0.weightLbs }
        guard let minW = weights.min(), let maxW = weights.max() else { return 0...200 }
        let padding = max((maxW - minW) * 0.15, 2)
        return (minW - padding)...(maxW + padding)
    }
}

// MARK: - Calorie Chart Section

struct CalorieChartSection: View {
    let dailyCalories: [(date: Date, calories: Int)]
    let calorieGoal: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Calories")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                Spacer()
                if !dailyCalories.isEmpty {
                    let avg = dailyCalories.reduce(0) { $0 + $1.calories } / max(dailyCalories.count, 1)
                    Text("Avg: \(avg) kcal")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }

            if dailyCalories.isEmpty {
                emptyState("No food logged yet")
            } else {
                Chart {
                    ForEach(dailyCalories, id: \.date) { item in
                        BarMark(
                            x: .value("Date", item.date, unit: .day),
                            y: .value("Calories", item.calories)
                        )
                        .foregroundStyle(
                            LinearGradient(colors: AppColors.calorieGradient, startPoint: .bottom, endPoint: .top)
                        )
                        .cornerRadius(4)
                    }

                    RuleMark(y: .value("Goal", calorieGoal))
                        .foregroundStyle(AppColors.calorie.opacity(0.6))
                        .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                        .annotation(position: .top, alignment: .trailing) {
                            Text("Goal")
                                .font(.caption2)
                                .foregroundStyle(.secondary)
                        }
                }
                .chartXAxis {
                    AxisMarks(values: .stride(by: .day, count: calorieXStride)) { _ in
                        AxisGridLine()
                        AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    }
                }
                .frame(height: 180)
            }
        }
        .padding()
        .background(AppColors.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var calorieXStride: Int {
        let count = dailyCalories.count
        if count <= 7 { return 1 }
        if count <= 30 { return 5 }
        return 7
    }
}

// MARK: - Macro Averages Section

struct MacroAveragesSection: View {
    let avgProtein: Int
    let avgCarbs: Int
    let avgFat: Int
    let proteinGoal: Int
    let carbsGoal: Int
    let fatGoal: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Macro Averages")
                .font(.system(.headline, design: .rounded, weight: .semibold))

            MacroProgressRow(label: "Protein", current: avgProtein, goal: proteinGoal, color: AppColors.protein, gradientColors: AppColors.proteinGradient)
            MacroProgressRow(label: "Carbs", current: avgCarbs, goal: carbsGoal, color: AppColors.carbs, gradientColors: AppColors.carbsGradient)
            MacroProgressRow(label: "Fat", current: avgFat, goal: fatGoal, color: AppColors.fat, gradientColors: AppColors.fatGradient)
        }
        .padding()
        .background(AppColors.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct MacroProgressRow: View {
    let label: String
    let current: Int
    let goal: Int
    let color: Color
    let gradientColors: [Color]

    private var progress: Double {
        goal > 0 ? min(Double(current) / Double(goal), 1.0) : 0
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Text(label)
                    .font(.system(.subheadline, design: .rounded, weight: .medium))
                Spacer()
                Text("\(current)g / \(goal)g")
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(color.opacity(0.12))

                    Capsule()
                        .fill(LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(6, geo.size.width * progress))
                        .shadow(color: color.opacity(0.3), radius: 4, y: 2)
                }
            }
            .frame(height: 8)
        }
    }
}

// MARK: - Stats Section

struct StatsSection: View {
    let streak: Int
    let daysOnTarget: Int
    let totalEntries: Int
    let bestStreak: Int

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Streaks & Stats")
                .font(.system(.headline, design: .rounded, weight: .semibold))

            LazyVGrid(columns: [GridItem(.flexible()), GridItem(.flexible())], spacing: 12) {
                StatTile(icon: "flame.fill", label: "Current Streak", value: "\(streak) days", color: AppColors.calorie)
                StatTile(icon: "trophy.fill", label: "Best Streak", value: "\(bestStreak) days", color: AppColors.carbs)
                StatTile(icon: "target", label: "Days on Target", value: "\(daysOnTarget)", color: AppColors.protein)
                StatTile(icon: "fork.knife", label: "Total Entries", value: "\(totalEntries)", color: AppColors.fat)
            }
        }
        .padding()
        .background(AppColors.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StatTile: View {
    let icon: String
    let label: String
    let value: String
    let color: Color

    var body: some View {
        VStack(spacing: 6) {
            Image(systemName: icon)
                .font(.title2)
                .foregroundStyle(color)

            Text(value)
                .font(.system(.title3, design: .rounded, weight: .bold))

            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(color.opacity(0.08))
        .clipShape(RoundedRectangle(cornerRadius: 12))
    }
}

struct StatBadge: View {
    let label: String
    let value: String

    var body: some View {
        VStack(spacing: 2) {
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
        }
    }
}

// MARK: - Log Weight Sheet

struct LogWeightSheet: View {
    @Environment(\.dismiss) private var dismiss
    @State private var weightText = ""
    let currentWeightLbs: Double
    let onSave: (Double) -> Void

    var body: some View {
        NavigationStack {
            VStack(spacing: 24) {
                Text("Log Weight")
                    .font(.system(.title2, design: .rounded, weight: .bold))

                VStack(spacing: 8) {
                    TextField("Weight", text: $weightText)
                        .font(.system(size: 48, weight: .bold, design: .rounded))
                        .multilineTextAlignment(.center)
                        .keyboardType(.decimalPad)

                    Text("lbs")
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                .padding(.vertical, 20)

                Button {
                    if let lbs = Double(weightText), lbs > 0 {
                        onSave(lbs / 2.20462)
                        dismiss()
                    }
                } label: {
                    Text("Save")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(
                            LinearGradient(colors: AppColors.calorieGradient, startPoint: .leading, endPoint: .trailing)
                        )
                        .foregroundStyle(.white)
                        .clipShape(RoundedRectangle(cornerRadius: 14))
                }
                .disabled(Double(weightText) == nil || (Double(weightText) ?? 0) <= 0)
                .opacity(Double(weightText) != nil && (Double(weightText) ?? 0) > 0 ? 1.0 : 0.5)

                Spacer()
            }
            .padding(24)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .onAppear {
            weightText = String(format: "%.1f", currentWeightLbs)
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Helpers

private func emptyState(_ message: String) -> some View {
    Text(message)
        .font(.system(.subheadline, design: .rounded))
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, minHeight: 80)
}
