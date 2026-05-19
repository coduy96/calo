import SwiftUI
import Charts

// MARK: - Time Range

enum TimeRange: String, CaseIterable {
    case week = "1W"
    case month = "1M"
    case threeMonths = "3M"
    case sixMonths = "6M"
    case year = "1Y"
    case allTime = "All"

    var days: Int {
        switch self {
        case .week: 7
        case .month: 30
        case .threeMonths: 90
        case .sixMonths: 180
        case .year: 365
        case .allTime: 3650
        }
    }

    var displayName: LocalizedStringKey {
        switch self {
        case .week: "1W"
        case .month: "1M"
        case .threeMonths: "3M"
        case .sixMonths: "6M"
        case .year: "1Y"
        case .allTime: "All"
        }
    }

    func dateRange() -> ClosedRange<Date> {
        let calendar = Calendar.current
        let end = calendar.startOfDay(for: .now).addingTimeInterval(86399)
        let start = calendar.date(byAdding: .day, value: -(days - 1), to: calendar.startOfDay(for: .now))!
        return start...end
    }
}

// MARK: - Weight Chart Section

struct WeightChartSection: View {
    let weightEntries: [WeightEntry]
    let goalWeightKg: Double?
    let currentWeightKg: Double?
    let onLogWeight: () -> Void
    /// Selected time-range window. When non-nil, drives the chart's x-axis
    /// domain so the visible span reflects the picker selection even if the
    /// data is sparse. `nil` means auto-fit to data (used for `.allTime`).
    var dateRange: ClosedRange<Date>? = nil
    @AppStorage("useMetric") private var useMetric = false

    private func displayWeight(_ kg: Double) -> Double {
        useMetric ? kg : kg * 2.20462
    }

    private var unit: String { useMetric ? "kg" : "lbs" }

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
                emptyState(LocalizedStringKey("Log your first weight to see trends"))
            } else {
                // Current / Goal row
                HStack(spacing: 16) {
                    if let current = currentWeightKg {
                        StatBadge(label: LocalizedStringKey("Current"), value: String(format: "%.1f %@", displayWeight(current), unit))
                    }
                    if let goal = goalWeightKg {
                        StatBadge(label: LocalizedStringKey("Goal"), value: String(format: "%.1f %@", displayWeight(goal), unit))
                    }
                }

                Chart {
                    ForEach(weightEntries) { entry in
                        LineMark(
                            x: .value("Date", entry.date, unit: .day),
                            y: .value("Weight", displayWeight(entry.weightKg))
                        )
                        .foregroundStyle(AppColors.calorie)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        PointMark(
                            x: .value("Date", entry.date, unit: .day),
                            y: .value("Weight", displayWeight(entry.weightKg))
                        )
                        .foregroundStyle(AppColors.calorie)
                        .symbolSize(30)
                    }

                    if let goalKg = goalWeightKg {
                        RuleMark(y: .value("Goal", displayWeight(goalKg)))
                            .foregroundStyle(.green.opacity(0.7))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    }
                }
                .chartYScale(domain: weightYDomain)
                .chartXScaleIfNeeded(dateRange)
                .chartXAxis { adaptiveDateAxis(spanDays: chartSpanDays) }
                .chartYAxis { numericYAxis() }
                .chartPlotStyle { $0.padding(.trailing, 6) }
                .frame(height: 180)
            }
        }
        .padding()
        .background(AppColors.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var chartSpanDays: Int {
        axisSpanDays(for: dateRange, fallback: weightEntries.map(\.date))
    }

    private var weightYDomain: ClosedRange<Double> {
        var weights = weightEntries.map { displayWeight($0.weightKg) }
        if let goalKg = goalWeightKg { weights.append(displayWeight(goalKg)) }
        guard let minW = weights.min(), let maxW = weights.max() else { return 0...200 }
        let padding = max((maxW - minW) * 0.15, 2)
        return (minW - padding)...(maxW + padding)
    }
}

// MARK: - Calorie Chart Section

struct CalorieChartSection: View {
    let dailyCalories: [(date: Date, calories: Int)]
    let calorieGoal: Int
    var dateRange: ClosedRange<Date>? = nil

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
                emptyState(LocalizedStringKey("No food logged yet"))
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
                }
                .chartXScaleIfNeeded(dateRange)
                .chartXAxis { adaptiveDateAxis(spanDays: chartSpanDays) }
                .chartYAxis { compactCalorieYAxis() }
                .chartPlotStyle { $0.padding(.trailing, 6) }
                .frame(height: 180)
            }
        }
        .padding()
        .background(AppColors.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var chartSpanDays: Int {
        axisSpanDays(for: dateRange, fallback: dailyCalories.map(\.date))
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

            MacroProgressRow(label: LocalizedStringKey("Protein"), current: avgProtein, goal: proteinGoal, color: AppColors.protein, gradientColors: AppColors.proteinGradient)
            MacroProgressRow(label: LocalizedStringKey("Carbs"), current: avgCarbs, goal: carbsGoal, color: AppColors.carbs, gradientColors: AppColors.carbsGradient)
            MacroProgressRow(label: LocalizedStringKey("Fat"), current: avgFat, goal: fatGoal, color: AppColors.fat, gradientColors: AppColors.fatGradient)
        }
        .padding()
        .background(AppColors.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct MacroProgressRow: View {
    let label: LocalizedStringKey
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
                Text(String(format: String(localized: "%lldg / %lldg"), current, goal))
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
                StatTile(icon: "flame.fill", label: LocalizedStringKey("Current Streak"), value: String(format: String(localized: "%lld days"), streak), color: AppColors.calorie)
                StatTile(icon: "trophy.fill", label: LocalizedStringKey("Best Streak"), value: String(format: String(localized: "%lld days"), bestStreak), color: AppColors.carbs)
                StatTile(icon: "target", label: LocalizedStringKey("Days on Target"), value: "\(daysOnTarget)", color: AppColors.protein)
                StatTile(icon: "fork.knife", label: LocalizedStringKey("Total Entries"), value: "\(totalEntries)", color: AppColors.fat)
            }
        }
        .padding()
        .background(AppColors.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

struct StatTile: View {
    let icon: String
    let label: LocalizedStringKey
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
    let label: LocalizedStringKey
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
    @AppStorage("useMetric") private var useMetric = false
    let currentWeightKg: Double
    let onSave: (Double) -> Void

    @State private var wholeNumber: Int
    @State private var decimal: Int

    init(currentWeightKg: Double, onSave: @escaping (Double) -> Void) {
        self.currentWeightKg = currentWeightKg
        self.onSave = onSave
        // Respect @AppStorage at the time the sheet is created.
        let metric = UserDefaults.standard.bool(forKey: "useMetric")
        let displayValue = metric ? currentWeightKg : currentWeightKg * 2.20462
        let whole = Int(displayValue)
        let dec = min(9, max(0, Int((displayValue - Double(whole)) * 10 + 0.5)))
        _wholeNumber = State(initialValue: whole)
        _decimal = State(initialValue: dec)
    }

    private var selectedValue: Double {
        Double(wholeNumber) + Double(decimal) / 10.0
    }

    private var selectedKg: Double {
        useMetric ? selectedValue : selectedValue / 2.20462
    }

    private var unit: String { useMetric ? "kg" : "lbs" }
    private var wholeRange: ClosedRange<Int> { useMetric ? 20...250 : 50...500 }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Log Weight")
                    .font(.system(.title2, design: .rounded, weight: .bold))

                // Scroll wheel pickers
                HStack(spacing: 0) {
                    Picker("Whole", selection: $wholeNumber) {
                        ForEach(wholeRange, id: \.self) { num in
                            Text("\(num)").tag(num)
                                .font(.system(.title2, design: .rounded, weight: .medium))
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)
                    .clipped()

                    Text(".")
                        .font(.system(size: 36, weight: .bold, design: .rounded))
                        .offset(y: -1)

                    Picker("Decimal", selection: $decimal) {
                        ForEach(0...9, id: \.self) { num in
                            Text("\(num)").tag(num)
                                .font(.system(.title2, design: .rounded, weight: .medium))
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 70)
                    .clipped()

                    Text(unit)
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }

                Button {
                    onSave(selectedKg)
                    dismiss()
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
                .padding(.horizontal, 24)

                Spacer()
            }
            .padding(.top, 24)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Weight History Link (tap to open full list)

struct WeightHistoryLink: View {
    let totalCount: Int
    let onTap: () -> Void

    var body: some View {
        Button(action: onTap) {
            HStack(spacing: 12) {
                Image(systemName: "list.bullet.rectangle")
                    .font(.system(size: 16, weight: .medium))
                    .foregroundStyle(AppColors.calorie)
                    .frame(width: 28, height: 28)
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weight History")
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .foregroundStyle(.primary)
                    Text(
                        totalCount == 1
                            ? String(format: String(localized: "%lld entry · tap to view or delete"), totalCount)
                            : String(format: String(localized: "%lld entries · tap to view or delete"), totalCount)
                    )
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.secondary)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(.tertiary)
            }
            .padding(.vertical, 12)
            .padding(.horizontal, 14)
            .background(AppColors.appCard, in: RoundedRectangle(cornerRadius: 14))
        }
        .buttonStyle(.plain)
    }
}

// MARK: - All Weight History (full-screen sheet)

struct AllWeightHistoryView: View {
    let entries: [WeightEntry]
    let useMetric: Bool
    let onDelete: (WeightEntry) -> Void

    @Environment(\.dismiss) private var dismiss
    @State private var pendingDeletion: WeightEntry?
    // Local mirror so the list updates immediately after deletion without needing the parent to re-bind.
    @State private var visibleEntries: [WeightEntry] = []

    var body: some View {
        NavigationStack {
            List {
                ForEach(visibleEntries) { entry in
                    HStack {
                        VStack(alignment: .leading, spacing: 2) {
                            Text(displayWeight(entry.weightKg, useMetric: useMetric))
                                .font(.system(.body, design: .rounded, weight: .medium))
                            Text(weightHistoryFormatter.string(from: entry.date))
                                .font(.system(.caption, design: .rounded))
                                .foregroundStyle(.secondary)
                        }
                        Spacer()
                    }
                    .swipeActions(edge: .trailing) {
                        Button(role: .destructive) {
                            pendingDeletion = entry
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle("Weight History")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button("Done") { dismiss() }
                }
            }
        }
        .onAppear { visibleEntries = entries }
        .alert("Delete Weight Entry", isPresented: Binding(
            get: { pendingDeletion != nil },
            set: { if !$0 { pendingDeletion = nil } }
        )) {
            Button("Cancel", role: .cancel) { pendingDeletion = nil }
            Button("Delete", role: .destructive) {
                if let entry = pendingDeletion {
                    visibleEntries.removeAll { $0.id == entry.id }
                    onDelete(entry)
                }
                pendingDeletion = nil
            }
        } message: {
            if let entry = pendingDeletion {
                Text(String(
                    format: String(localized: "Remove %@'s entry of %@? This also deletes the matching sample from Apple Health."),
                    weightHistoryFormatter.string(from: entry.date),
                    displayWeight(entry.weightKg, useMetric: useMetric)
                ))
            }
        }
    }
}

private let weightHistoryFormatter: DateFormatter = {
    let f = DateFormatter()
    f.dateFormat = "MMM d, yyyy"
    return f
}()

private func displayWeight(_ kg: Double, useMetric: Bool) -> String {
    if useMetric {
        return String(format: "%.1f kg", kg)
    }
    let lbs = kg * 2.20462
    return String(format: "%.1f lb", lbs)
}

// MARK: - Body Metrics Section (Weight / Body Fat toggle)

enum BodyMetric: String, CaseIterable, Identifiable {
    case weight, bodyFat
    var id: String { rawValue }
    var displayName: LocalizedStringKey {
        switch self {
        case .weight: LocalizedStringKey("Weight")
        case .bodyFat: LocalizedStringKey("Body Fat")
        }
    }
}

/// Single card with a segmented Weight / Body Fat toggle at the top and the
/// matching chart below — replaces the two stacked cards. The toggle is only
/// rendered when both metrics are available; users without body-fat data see
/// the bare WeightChartSection (no toggle, identical to the v3.1 layout) so
/// nothing changes for users who never opted into body-fat tracking.
struct BodyMetricsSection: View {
    let weightEntries: [WeightEntry]
    let goalWeightKg: Double?
    let currentWeightKg: Double?
    let onLogWeight: () -> Void

    let bodyFatEntries: [BodyFatEntry]
    let goalBodyFatFraction: Double?
    let currentBodyFatFraction: Double?
    let onLogBodyFat: () -> Void

    /// True when the user has opted into body-fat tracking — drives whether
    /// the segmented toggle renders at all.
    let bodyFatAvailable: Bool

    var dateRange: ClosedRange<Date>? = nil

    @State private var metric: BodyMetric = .weight

    var body: some View {
        VStack(spacing: 12) {
            if bodyFatAvailable {
                Picker("Metric", selection: $metric.animation(.snappy)) {
                    ForEach(BodyMetric.allCases) { m in
                        Text(m.displayName).tag(m)
                    }
                }
                .pickerStyle(.segmented)
            }

            // Render the active metric. Both children carry their own card
            // background, so the parent VStack just stacks them naturally.
            switch metric {
            case .weight:
                WeightChartSection(
                    weightEntries: weightEntries,
                    goalWeightKg: goalWeightKg,
                    currentWeightKg: currentWeightKg,
                    onLogWeight: onLogWeight,
                    dateRange: dateRange
                )
                // Swipe right to flip to Body Fat (only when available).
                .gesture(
                    bodyFatAvailable
                        ? DragGesture(minimumDistance: 30)
                            .onEnded { value in
                                if value.translation.width < -50 {
                                    withAnimation(.snappy) { metric = .bodyFat }
                                }
                            }
                        : nil
                )
            case .bodyFat:
                BodyFatChartSection(
                    entries: bodyFatEntries,
                    goalBodyFatFraction: goalBodyFatFraction,
                    currentBodyFatFraction: currentBodyFatFraction,
                    onLogBodyFat: onLogBodyFat,
                    dateRange: dateRange
                )
                // Swipe left to flip back to Weight.
                .gesture(
                    DragGesture(minimumDistance: 30)
                        .onEnded { value in
                            if value.translation.width > 50 {
                                withAnimation(.snappy) { metric = .weight }
                            }
                        }
                )
            }
        }
    }
}

// MARK: - Body Fat Chart Section

/// Visual twin of WeightChartSection for body-fat % readings. Goal line is
/// drawn as a dashed RuleMark in green if `goalBodyFatFraction` is set. The
/// goal value is purely visual — it never enters BMR / TDEE / macro math.
struct BodyFatChartSection: View {
    let entries: [BodyFatEntry]
    let goalBodyFatFraction: Double?
    let currentBodyFatFraction: Double?
    let onLogBodyFat: () -> Void
    var dateRange: ClosedRange<Date>? = nil

    private func displayPercent(_ fraction: Double) -> Double {
        fraction * 100
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Text("Body Fat")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                Spacer()
                Button(action: onLogBodyFat) {
                    Label("Log Body Fat", systemImage: "plus.circle.fill")
                        .font(.system(.subheadline, design: .rounded, weight: .medium))
                        .foregroundStyle(AppColors.calorie)
                }
            }

            if entries.isEmpty {
                emptyState(LocalizedStringKey("Log your first body fat % to see trends"))
            } else {
                HStack(spacing: 16) {
                    if let current = currentBodyFatFraction {
                        StatBadge(label: LocalizedStringKey("Current"), value: String(format: "%.1f%%", displayPercent(current)))
                    }
                    if let goal = goalBodyFatFraction {
                        StatBadge(label: LocalizedStringKey("Goal"), value: String(format: "%.1f%%", displayPercent(goal)))
                    }
                }

                Chart {
                    ForEach(entries) { entry in
                        LineMark(
                            x: .value("Date", entry.date, unit: .day),
                            y: .value("Body Fat", displayPercent(entry.bodyFatFraction))
                        )
                        .foregroundStyle(AppColors.calorie)
                        .interpolationMethod(.catmullRom)
                        .lineStyle(StrokeStyle(lineWidth: 2))

                        PointMark(
                            x: .value("Date", entry.date, unit: .day),
                            y: .value("Body Fat", displayPercent(entry.bodyFatFraction))
                        )
                        .foregroundStyle(AppColors.calorie)
                        .symbolSize(30)
                    }

                    if let goalFraction = goalBodyFatFraction {
                        RuleMark(y: .value("Goal", displayPercent(goalFraction)))
                            .foregroundStyle(.green.opacity(0.7))
                            .lineStyle(StrokeStyle(lineWidth: 1.5, dash: [6, 4]))
                    }
                }
                .chartYScale(domain: bodyFatYDomain)
                .chartXScaleIfNeeded(dateRange)
                .chartXAxis { adaptiveDateAxis(spanDays: chartSpanDays) }
                .chartYAxis { numericYAxis() }
                .chartPlotStyle { $0.padding(.trailing, 6) }
                .frame(height: 180)
            }
        }
        .padding()
        .background(AppColors.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var chartSpanDays: Int {
        axisSpanDays(for: dateRange, fallback: entries.map(\.date))
    }

    private var bodyFatYDomain: ClosedRange<Double> {
        var values = entries.map { displayPercent($0.bodyFatFraction) }
        if let goal = goalBodyFatFraction { values.append(displayPercent(goal)) }
        guard let minV = values.min(), let maxV = values.max() else { return 0...60 }
        let padding = max((maxV - minV) * 0.15, 1)
        return max(0, minV - padding)...(maxV + padding)
    }
}

// MARK: - Log Body Fat Sheet

/// Single-wheel picker for body-fat %. Whole-number precision (matches
/// BodyFatPickerSheet in Settings) — body-fat measurements rarely justify
/// 0.1% resolution given the noise of calipers / smart scales.
struct LogBodyFatSheet: View {
    @Environment(\.dismiss) private var dismiss
    let currentFraction: Double
    let onSave: (Double) -> Void

    @State private var percentage: Int

    init(currentFraction: Double, onSave: @escaping (Double) -> Void) {
        self.currentFraction = currentFraction
        self.onSave = onSave
        _percentage = State(initialValue: Int(currentFraction * 100))
    }

    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                Text("Log Body Fat")
                    .font(.system(.title2, design: .rounded, weight: .bold))

                HStack(spacing: 0) {
                    Picker("Percentage", selection: $percentage) {
                        ForEach(3...60, id: \.self) { n in
                            Text("\(n)").tag(n)
                                .font(.system(.title2, design: .rounded, weight: .medium))
                        }
                    }
                    .pickerStyle(.wheel)
                    .frame(width: 100)
                    .clipped()

                    Text("%")
                        .font(.system(.title3, design: .rounded))
                        .foregroundStyle(.secondary)
                        .padding(.leading, 4)
                }

                Button {
                    onSave(Double(percentage) / 100.0)
                    dismiss()
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
                .padding(.horizontal, 24)

                Spacer()
            }
            .padding(.top, 24)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") { dismiss() }
                }
            }
        }
        .presentationDetents([.medium])
    }
}

// MARK: - Helpers

private func emptyState(_ message: LocalizedStringKey) -> some View {
    Text(message)
        .font(.system(.subheadline, design: .rounded))
        .foregroundStyle(.secondary)
        .frame(maxWidth: .infinity, minHeight: 80)
}

/// Day span used to drive axis label density and date format. Prefers the
/// picker's selected window so the axis stays stable as data trickles in; for
/// `.allTime` (range == nil) we derive span from the first/last data points.
private func axisSpanDays(for dateRange: ClosedRange<Date>?, fallback dates: [Date]) -> Int {
    if let dateRange {
        let secs = dateRange.upperBound.timeIntervalSince(dateRange.lowerBound)
        return max(Int((secs / 86400).rounded()), 1)
    }
    guard let first = dates.min(), let last = dates.max() else { return 1 }
    let secs = last.timeIntervalSince(first)
    return max(Int((secs / 86400).rounded()), 1)
}

/// Tick count target for the x-axis. Picked so labels never collide on a
/// ~330pt-wide chart at the chosen format (≈48pt per label minimum).
private func axisLabelCount(spanDays: Int) -> Int {
    if spanDays <= 7 { return 4 }
    if spanDays <= 30 { return 5 }
    if spanDays <= 90 { return 4 }
    if spanDays <= 365 { return 5 }
    return 5
}

/// Adaptive x-axis builder shared by all three charts. Uses `.automatic` tick
/// placement (so SwiftUI rounds to nice dates) plus a span-appropriate format
/// — day+month for short windows, month-only for quarter/half-year, month+year
/// once we cross a year so the axis is unambiguous.
@AxisContentBuilder
private func adaptiveDateAxis(spanDays: Int) -> some AxisContent {
    AxisMarks(values: .automatic(desiredCount: axisLabelCount(spanDays: spanDays))) { value in
        AxisGridLine()
            .foregroundStyle(Color.secondary.opacity(0.18))
        AxisValueLabel(centered: false) {
            if let date = value.as(Date.self) {
                Text(date, format: axisDateFormat(spanDays: spanDays))
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private func axisDateFormat(spanDays: Int) -> Date.FormatStyle {
    if spanDays <= 90 {
        return .dateTime.day().month(.abbreviated)
    }
    if spanDays <= 365 {
        return .dateTime.month(.abbreviated)
    }
    return .dateTime.month(.abbreviated).year(.twoDigits)
}

/// Trailing numeric y-axis (used for weight and body-fat charts). Caption-2
/// rounded labels, soft gridlines, so the axis recedes into the background.
@AxisContentBuilder
private func numericYAxis() -> some AxisContent {
    AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { _ in
        AxisGridLine()
            .foregroundStyle(Color.secondary.opacity(0.18))
        AxisValueLabel()
            .font(.system(.caption2, design: .rounded))
            .foregroundStyle(.secondary)
    }
}

/// Trailing calorie y-axis — same styling as `numericYAxis` but formats large
/// values with a `k` suffix so e.g. 3000 → "3k" instead of "3.000".
@AxisContentBuilder
private func compactCalorieYAxis() -> some AxisContent {
    AxisMarks(position: .trailing, values: .automatic(desiredCount: 4)) { value in
        AxisGridLine()
            .foregroundStyle(Color.secondary.opacity(0.18))
        AxisValueLabel {
            if let kcal = value.as(Int.self) {
                Text(compactKcal(kcal))
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }
}

private func compactKcal(_ value: Int) -> String {
    if value >= 1_000 {
        let k = Double(value) / 1_000.0
        if k.truncatingRemainder(dividingBy: 1) == 0 {
            return "\(Int(k))k"
        }
        return String(format: "%.1fk", k)
    }
    return "\(value)"
}

private extension View {
    /// Apply `.chartXScale(domain:)` only when a range is provided. For
    /// `.allTime` (range == nil) the chart auto-fits to data — a fixed
    /// 10-year axis would crush real entries against the right edge.
    @ViewBuilder
    func chartXScaleIfNeeded(_ dateRange: ClosedRange<Date>?) -> some View {
        if let dateRange {
            self.chartXScale(domain: dateRange)
        } else {
            self
        }
    }
}
