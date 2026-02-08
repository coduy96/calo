import Foundation
import SwiftUI

@Observable
class FoodStore {
    private(set) var entries: [FoodEntry] = []
    var onEntriesChanged: (() -> Void)?

    private let storageKey = "foodEntries"

    init() {
        loadEntries()
    }

    var todayEntries: [FoodEntry] {
        let calendar = Calendar.current
        return entries
            .filter { calendar.isDateInToday($0.timestamp) }
            .sorted { $0.timestamp > $1.timestamp }
    }

    var todayEntriesByMeal: [(meal: MealType, entries: [FoodEntry])] {
        let calendar = Calendar.current
        let today = entries
            .filter { calendar.isDateInToday($0.timestamp) }
            .sorted { $0.timestamp > $1.timestamp }

        return MealType.allCases.compactMap { meal in
            let mealEntries = today.filter { $0.mealType == meal }
            return mealEntries.isEmpty ? nil : (meal, mealEntries)
        }
    }

    var todayCalories: Int {
        todayEntries.reduce(0) { $0 + $1.calories }
    }

    var todayProtein: Int {
        todayEntries.reduce(0) { $0 + $1.protein }
    }

    var todayCarbs: Int {
        todayEntries.reduce(0) { $0 + $1.carbs }
    }

    var todayFat: Int {
        todayEntries.reduce(0) { $0 + $1.fat }
    }

    // MARK: - Date-parameterized queries

    func entries(for date: Date) -> [FoodEntry] {
        let calendar = Calendar.current
        return entries
            .filter { calendar.isDate($0.timestamp, inSameDayAs: date) }
            .sorted { $0.timestamp > $1.timestamp }
    }

    func entriesByMeal(for date: Date) -> [(meal: MealType, entries: [FoodEntry])] {
        let dayEntries = entries(for: date)
        return MealType.allCases.compactMap { meal in
            let mealEntries = dayEntries.filter { $0.mealType == meal }
            return mealEntries.isEmpty ? nil : (meal, mealEntries)
        }
    }

    func calories(for date: Date) -> Int {
        entries(for: date).reduce(0) { $0 + $1.calories }
    }

    func protein(for date: Date) -> Int {
        entries(for: date).reduce(0) { $0 + $1.protein }
    }

    func carbs(for date: Date) -> Int {
        entries(for: date).reduce(0) { $0 + $1.carbs }
    }

    func fat(for date: Date) -> Int {
        entries(for: date).reduce(0) { $0 + $1.fat }
    }

    func addEntry(_ entry: FoodEntry) {
        entries.append(entry)
        saveEntries()
        onEntriesChanged?()
    }

    func deleteEntry(_ entry: FoodEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
        onEntriesChanged?()
    }

    private func saveEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    private func loadEntries() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([FoodEntry].self, from: data)
        else { return }
        entries = decoded
    }
}
