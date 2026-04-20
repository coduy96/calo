import SwiftUI

/// Progress-tab card that predicts the user's future weight from their logged calorie history,
/// weight history, and profile. Thermodynamic math runs instantly; an optional second tap
/// sends the summary to the selected LLM provider for a plain-English suggestion.
struct WeightForecastSection: View {
    let forecast: WeightForecast?
    let useMetric: Bool
    let isGeneratingInsight: Bool
    let aiInsight: String?
    let aiError: String?
    let lastGenerated: Date?
    let onAnalyze: () -> Void
    let onAskAI: () -> Void

    private static let dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        return f
    }()

    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            // Header
            HStack {
                Label {
                    Text("Weight Forecast")
                        .font(.system(.headline, design: .rounded, weight: .semibold))
                } icon: {
                    Image(systemName: "sparkles")
                        .foregroundStyle(AppColors.calorie)
                }
                Spacer()
            }

            if let f = forecast, f.hasEnoughData {
                // Predicted-weight hero
                VStack(spacing: 4) {
                    Text("Expected in 30 days")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                    HStack(alignment: .firstTextBaseline, spacing: 4) {
                        Text(displayWeight(f.predictedWeight30dKg))
                            .font(.system(size: 38, weight: .bold, design: .rounded))
                            .foregroundStyle(
                                LinearGradient(colors: AppColors.calorieGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                            )
                            .contentTransition(.numericText())
                        Text(useMetric ? "kg" : "lbs")
                            .font(.system(.title3, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    Text(deltaDescription(f: f))
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(f.predictedWeeklyChangeKg == 0 ? .secondary : (matchesGoalDirection(f) ? .green : AppColors.calorie))
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 4)

                Divider()

                // Key numbers grid
                HStack(spacing: 12) {
                    statCell(label: "Daily Balance",
                             value: String(format: "%@%d kcal", f.dailyEnergyBalance >= 0 ? "+" : "", f.dailyEnergyBalance))
                    statCell(label: "Predicted",
                             value: weeklyChange(f.predictedWeeklyChangeKg))
                    if let observed = f.observedWeeklyChangeKg {
                        statCell(label: "Observed", value: weeklyChange(observed))
                    }
                }

                // 60 / 90 day projections
                HStack(spacing: 12) {
                    projectionCell(label: "In 60 days", kg: f.predictedWeight60dKg)
                    projectionCell(label: "In 90 days", kg: f.predictedWeight90dKg)
                    if let reachDate = f.goalReachDate {
                        projectionCell(label: "Goal on", value: Self.dateFormatter.string(from: reachDate))
                    }
                }

                if f.trendsDisagree {
                    Label {
                        Text("Your logged calories and scale weight don't quite match. You may be under-logging food.")
                            .font(.system(.caption, design: .rounded))
                    } icon: {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .foregroundStyle(.orange)
                    }
                    .foregroundStyle(.secondary)
                }

                Text("Based on \(f.daysOfFoodData) days of food and \(f.weightEntriesUsed) weight entries.")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.tertiary)

                Divider()

                // AI insight block
                if isGeneratingInsight {
                    HStack(spacing: 10) {
                        ProgressView()
                        Text("Analyzing with AI…")
                            .font(.system(.footnote, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                } else if let insight = aiInsight {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                                .font(.system(size: 12))
                                .foregroundStyle(AppColors.calorie)
                            Text("AI Suggestion")
                                .font(.system(.caption, design: .rounded, weight: .medium))
                                .foregroundStyle(.secondary)
                            Spacer()
                            Button(action: onAskAI) {
                                Image(systemName: "arrow.clockwise")
                                    .font(.system(size: 12))
                                    .foregroundStyle(.secondary)
                            }
                            .buttonStyle(.plain)
                        }
                        Text(insight)
                            .font(.system(.footnote, design: .rounded))
                            .fixedSize(horizontal: false, vertical: true)
                    }
                    .padding(10)
                    .background(AppColors.calorie.opacity(0.08), in: RoundedRectangle(cornerRadius: 10))
                } else if let err = aiError {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(err)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.red)
                        Button("Try Again", action: onAskAI)
                            .font(.system(.caption, design: .rounded, weight: .medium))
                            .tint(AppColors.calorie)
                    }
                } else {
                    Button(action: onAskAI) {
                        HStack {
                            Image(systemName: "wand.and.stars")
                            Text("Ask AI for a Suggestion")
                        }
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 10)
                        .background(AppColors.calorie.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppColors.calorie)
                }
            } else {
                // Empty state
                VStack(alignment: .leading, spacing: 8) {
                    Text("Log at least 2 days of food and 2 weights to see your forecast.")
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.secondary)
                    Button(action: onAnalyze) {
                        Text("Check Now")
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .frame(maxWidth: .infinity)
                            .padding(.vertical, 10)
                            .background(AppColors.calorie.opacity(0.15), in: RoundedRectangle(cornerRadius: 10))
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(AppColors.calorie)
                }
            }
        }
        .padding(14)
        .background(AppColors.appCard, in: RoundedRectangle(cornerRadius: 14))
    }

    private func displayWeight(_ kg: Double) -> String {
        useMetric ? String(format: "%.1f", kg) : String(format: "%.1f", kg * 2.20462)
    }

    private func weeklyChange(_ kg: Double) -> String {
        let val = useMetric ? kg : kg * 2.20462
        let unit = useMetric ? "kg" : "lbs"
        return String(format: "%@%.2f %@/wk", val >= 0 ? "+" : "", val, unit)
    }

    private func deltaDescription(f: WeightForecast) -> String {
        let delta = f.predictedWeight30dKg - f.currentWeightKg
        let val = useMetric ? delta : delta * 2.20462
        let unit = useMetric ? "kg" : "lbs"
        if abs(val) < 0.1 { return "Holding steady at current pace" }
        return String(format: "%@%.1f %@ from today", val >= 0 ? "+" : "", val, unit)
    }

    private func matchesGoalDirection(_ f: WeightForecast) -> Bool {
        f.goalReachDate != nil
    }

    @ViewBuilder
    private func statCell(label: String, value: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
            Text(value)
                .font(.system(.footnote, design: .rounded, weight: .semibold))
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func projectionCell(label: String, kg: Double? = nil, value: String? = nil) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            Text(label)
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.secondary)
            if let kg {
                HStack(alignment: .firstTextBaseline, spacing: 2) {
                    Text(displayWeight(kg))
                        .font(.system(.footnote, design: .rounded, weight: .semibold))
                    Text(useMetric ? "kg" : "lbs")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            } else if let value {
                Text(value)
                    .font(.system(.footnote, design: .rounded, weight: .semibold))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }
}
