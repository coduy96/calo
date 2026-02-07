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
        HStack(spacing: 4) {
            ForEach(0..<7, id: \.self) { index in
                dayTile(for: weekDates[index])
            }
        }
        .padding(.vertical, 4)
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
            VStack(spacing: 2) {
                Text(date.formatted(.dateTime.weekday(.narrow)))
                    .font(.caption2)
                    .fontWeight(.medium)

                Text(date.formatted(.dateTime.day()))
                    .font(.system(.callout, design: .rounded, weight: .semibold))
            }
            .foregroundStyle(isSelected ? .white : (isToday ? AppColors.calorie : .secondary))
            .frame(maxWidth: .infinity)
            .padding(.vertical, 10)
            .background {
                if isSelected {
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(LinearGradient(colors: AppColors.calorieGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                }
            }
        }
        .buttonStyle(.plain)
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
        VStack(spacing: 6) {
            Text("\(current)")
                .font(.system(.title2, design: .rounded, weight: .bold))
                .foregroundStyle(gradientColors.first ?? .primary)

            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    Capsule()
                        .fill(gradientColors.first?.opacity(0.18) ?? Color.gray.opacity(0.18))

                    Capsule()
                        .fill(LinearGradient(colors: gradientColors, startPoint: .leading, endPoint: .trailing))
                        .frame(width: max(4, geo.size.width * progress))
                        .animation(.spring(response: 0.6, dampingFraction: 0.85), value: current)
                }
            }
            .frame(height: 5)

            Text(label)
                .font(.caption)
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
