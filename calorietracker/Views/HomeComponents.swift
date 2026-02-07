import SwiftUI

// MARK: - Week Energy Strip

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
                let date = weekDates[index]
                dayColumn(for: date)
            }
        }
        .padding(.vertical, 4)
    }

    private func dayColumn(for date: Date) -> some View {
        let isSelected = Calendar.current.isDate(date, inSameDayAs: selectedDate)
        let isToday = Calendar.current.isDateInToday(date)
        let cals = caloriesForDate(date)
        let progress = calorieGoal > 0 ? min(Double(cals) / Double(calorieGoal), 1.0) : 0

        return Button {
            withAnimation(.snappy(duration: 0.3)) {
                selectedDate = date
            }
        } label: {
            VStack(spacing: 4) {
                Text(date.formatted(.dateTime.weekday(.narrow)))
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? .primary : .secondary)

                ZStack(alignment: .bottom) {
                    Capsule()
                        .fill(.quaternary)
                        .frame(width: 8, height: 40)

                    Capsule()
                        .fill(isSelected ? Color.accentColor : .gray.opacity(0.5))
                        .frame(width: 8, height: max(4, 40 * progress))
                }

                Text(date.formatted(.dateTime.day()))
                    .font(.caption2)
                    .fontWeight(isSelected ? .bold : .regular)
                    .foregroundStyle(isSelected ? .primary : .secondary)

                Circle()
                    .fill(Color.primary.opacity(isToday ? 1 : 0))
                    .frame(width: 4, height: 4)
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity)
    }
}

// MARK: - Macro Ring

struct MacroRing: View {
    let label: String
    let current: Int
    let goal: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Gauge(value: Double(current), in: 0...Double(max(goal, 1))) {
                EmptyView()
            } currentValueLabel: {
                Text("\(current)")
                    .font(.system(.caption, design: .rounded, weight: .bold))
            }
            .gaugeStyle(.accessoryCircularCapacity)
            .tint(color)
            .scaleEffect(1.4)
            .frame(width: 56, height: 56)

            Text("\(current)g")
                .font(.caption2)
                .fontWeight(.semibold)
            Text(label)
                .font(.caption2)
                .foregroundStyle(.secondary)
        }
    }
}
