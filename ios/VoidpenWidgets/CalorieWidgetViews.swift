import SwiftUI
import WidgetKit

/// Mirrors the main app theme colors without importing Theme.swift
/// (which lives in the main app target).
enum WidgetThemeColor: String {
    case fudPink
    case red
    case orange
    case green
    case mint
    case teal
    case blue
    case purple

    static let defaultColor: WidgetThemeColor = .orange

    static func color(for rawValue: String?) -> WidgetThemeColor {
        guard let rawValue else { return defaultColor }
        return WidgetThemeColor(rawValue: rawValue) ?? defaultColor
    }

    var color: Color {
        Color(hex: startHex)
    }

    var gradientColors: [Color] {
        [Color(hex: startHex), Color(hex: endHex)]
    }

    private var startHex: UInt {
        switch self {
        case .fudPink: return 0xFF375F
        case .red: return 0xFF3B30
        case .orange: return 0xFF5A00
        case .green: return 0x34C759
        case .mint: return 0x00C7BE
        case .teal: return 0x30B0C7
        case .blue: return 0x0A84FF
        case .purple: return 0xAF52DE
        }
    }

    private var endHex: UInt {
        switch self {
        case .fudPink: return 0xFF6B8A
        case .red: return 0xFF6961
        case .orange: return 0xFF8C00
        case .green: return 0x62D46F
        case .mint: return 0x66D4CF
        case .teal: return 0x64D2FF
        case .blue: return 0x5EAEFF
        case .purple: return 0xBF5AF2
        }
    }
}

enum WidgetPalette {
    static func calorie(for snapshot: WidgetSnapshot) -> Color {
        WidgetThemeColor.color(for: snapshot.themeColorRaw).color
    }

    static func calorieGradient(for snapshot: WidgetSnapshot) -> LinearGradient {
        LinearGradient(
            colors: WidgetThemeColor.color(for: snapshot.themeColorRaw).gradientColors,
            startPoint: .topLeading,
            endPoint: .bottomTrailing
        )
    }

    static var background: some ShapeStyle {
        Color(.systemBackground)
    }
}

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}

/// Top-level dispatcher — WidgetKit gives us an `Environment(\.widgetFamily)`.
struct CalorieWidgetView: View {
    let entry: CalorieEntry
    @Environment(\.widgetFamily) private var family

    var body: some View {
        switch family {
        case .systemSmall:       SmallCalorieView(snapshot: entry.snapshot)
        case .systemMedium:      MediumCalorieView(snapshot: entry.snapshot)
        case .accessoryCircular: CircularCalorieView(snapshot: entry.snapshot)
        case .accessoryRectangular: RectangularCalorieView(snapshot: entry.snapshot)
        case .accessoryInline:   InlineCalorieView(snapshot: entry.snapshot)
        default:                 SmallCalorieView(snapshot: entry.snapshot)
        }
    }
}

// MARK: - Home Screen

private struct SmallCalorieView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 6) {
                Image(systemName: "flame.fill")
                    .font(.system(size: 11, weight: .bold))
                    .foregroundStyle(WidgetPalette.calorieGradient(for: snapshot))
                Text("Today")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
            }

            ZStack {
                Circle()
                    .stroke(WidgetPalette.calorie(for: snapshot).opacity(0.15), lineWidth: 10)
                Circle()
                    .trim(from: 0, to: snapshot.calorieProgress)
                    .stroke(WidgetPalette.calorieGradient(for: snapshot), style: StrokeStyle(lineWidth: 10, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(snapshot.calories)")
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .minimumScaleFactor(0.7)
                        .lineLimit(1)
                    Text("/ \(snapshot.calorieGoal)")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)

            Text("\(snapshot.caloriesRemaining) kcal left")
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
        }
    }
}

private struct MediumCalorieView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle()
                    .stroke(WidgetPalette.calorie(for: snapshot).opacity(0.15), lineWidth: 9)
                Circle()
                    .trim(from: 0, to: snapshot.calorieProgress)
                    .stroke(WidgetPalette.calorieGradient(for: snapshot), style: StrokeStyle(lineWidth: 9, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                VStack(spacing: 0) {
                    Text("\(snapshot.calories)")
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .minimumScaleFactor(0.6)
                        .lineLimit(1)
                    Text("/ \(snapshot.calorieGoal)")
                        .font(.system(.caption2, design: .rounded))
                        .foregroundStyle(.secondary)
                    Text("kcal")
                        .font(.system(.caption2, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                }
            }
            .frame(width: 92, height: 92)

            VStack(alignment: .leading, spacing: 8) {
                MacroBar(label: "Protein", value: snapshot.protein, goal: snapshot.proteinGoal, progress: snapshot.proteinProgress, snapshot: snapshot)
                MacroBar(label: "Carbs",   value: snapshot.carbs,   goal: snapshot.carbsGoal,   progress: snapshot.carbsProgress, snapshot: snapshot)
                MacroBar(label: "Fat",     value: snapshot.fat,     goal: snapshot.fatGoal,     progress: snapshot.fatProgress, snapshot: snapshot)
            }
            .frame(maxWidth: .infinity)
        }
    }
}

private struct MacroBar: View {
    let label: String
    let value: Int
    let goal: Int
    let progress: Double
    let snapshot: WidgetSnapshot

    var body: some View {
        VStack(alignment: .leading, spacing: 3) {
            HStack {
                Text(label)
                    .font(.system(.caption2, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                Spacer()
                Text("\(value)g / \(goal)g")
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(.primary)
            }
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(WidgetPalette.calorie(for: snapshot).opacity(0.15))
                    Capsule()
                        .fill(WidgetPalette.calorieGradient(for: snapshot))
                        .frame(width: max(4, geo.size.width * progress))
                }
            }
            .frame(height: 6)
        }
    }
}

// MARK: - Lock Screen

/// Above-the-clock circular — ring showing today's calorie progress.
private struct CircularCalorieView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        ZStack {
            AccessoryWidgetBackground()
            Circle()
                .trim(from: 0, to: snapshot.calorieProgress)
                .stroke(style: StrokeStyle(lineWidth: 3.5, lineCap: .round))
                .rotationEffect(.degrees(-90))
                .padding(3)
            VStack(spacing: 0) {
                Text("\(snapshot.calories)")
                    .font(.system(.caption, design: .rounded, weight: .bold))
                    .minimumScaleFactor(0.6)
                    .lineLimit(1)
                Text("kcal")
                    .font(.system(size: 8, weight: .medium, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
        .widgetAccentable()
    }
}

private struct RectangularCalorieView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            ZStack {
                Circle()
                    .stroke(.secondary.opacity(0.3), lineWidth: 3)
                Circle()
                    .trim(from: 0, to: snapshot.calorieProgress)
                    .stroke(style: StrokeStyle(lineWidth: 3, lineCap: .round))
                    .rotationEffect(.degrees(-90))
                Image(systemName: "flame.fill")
                    .font(.system(size: 13, weight: .bold))
            }
            .frame(width: 42, height: 42)
            .widgetAccentable()

            VStack(alignment: .leading, spacing: 2) {
                Text("\(snapshot.calories)")
                    .font(.system(.title3, design: .rounded, weight: .bold))
                    .widgetAccentable()
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                Text("of \(snapshot.calorieGoal) kcal")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                Text("P\(snapshot.protein) · C\(snapshot.carbs) · F\(snapshot.fat)")
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
            }
            Spacer(minLength: 0)
        }
    }
}

private struct InlineCalorieView: View {
    let snapshot: WidgetSnapshot

    var body: some View {
        // Inline widgets get exactly one line of text; iOS ignores colors.
        Text("\(snapshot.calories) / \(snapshot.calorieGoal) kcal · \(snapshot.caloriesRemaining) left")
    }
}
