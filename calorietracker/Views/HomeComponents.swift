import SwiftUI

// MARK: - Week Day Selector

struct WeekEnergyStrip: View {
    @Binding var selectedDate: Date
    let caloriesForDate: (Date) -> Int
    let calorieGoal: Int

    private var weekDates: [Date] {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let weekday = calendar.component(.weekday, from: today)
        let startOfWeek = calendar.date(byAdding: .day, value: -(weekday - 1), to: today)!
        return (0..<7).map { calendar.date(byAdding: .day, value: $0, to: startOfWeek)! }
    }

    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<7, id: \.self) { index in
                dayTile(for: weekDates[index])
            }
        }
    }

    private func dayTile(for date: Date) -> some View {
        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
        let isToday = Calendar.current.isDateInToday(date)

        return Button {
            UIImpactFeedbackGenerator(style: .light).impactOccurred()
            withAnimation(.snappy(duration: 0.3)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 6) {
                Text(date.formatted(.dateTime.weekday(.narrow)))
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(isSelected ? AppColors.calorie : Color.secondary.opacity(0.6))

                Text(date.formatted(.dateTime.day()))
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .foregroundStyle(isSelected ? .white : (isToday ? AppColors.calorie : .primary))
                    .frame(width: 36, height: 36)
                    .background {
                        if isSelected {
                            Circle()
                                .fill(LinearGradient(colors: AppColors.calorieGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                                .shadow(color: AppColors.calorie.opacity(0.35), radius: 6, y: 3)
                        } else if isToday {
                            Circle()
                                .strokeBorder(AppColors.calorie.opacity(0.35), lineWidth: 1.5)
                        }
                    }
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Macro Card

struct MacroCard: View {
    let label: String
    let current: Int
    let goal: Int
    let gradientColors: [Color]

    private var progress: Double {
        goal > 0 ? min(Double(current) / Double(goal), 1.0) : 0
    }

    var body: some View {
        VStack(spacing: 8) {
            Text("\(current)")
                .font(.system(.title, design: .rounded, weight: .bold))
                .foregroundStyle(gradientColors.first ?? .primary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(gradientColors.first?.opacity(0.12) ?? Color.gray.opacity(0.12))

                    Capsule()
                        .fill(LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(6, geo.size.width * progress))
                        .shadow(color: (gradientColors.first ?? .clear).opacity(0.3), radius: 4, y: 2)
                        .animation(.spring(response: 0.8, dampingFraction: 0.75), value: current)
                }
            }
            .frame(height: 6)

            Text(label)
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)

            Text("\(max(goal - current, 0))g left")
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity)
    }
}
