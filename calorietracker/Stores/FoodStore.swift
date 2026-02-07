import Foundation
import SwiftUI

@Observable
class FoodStore {
    private(set) var entries: [FoodEntry] = []

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

    func addEntry(_ entry: FoodEntry) {
        entries.append(entry)
        saveEntries()
    }

    func deleteEntry(_ entry: FoodEntry) {
        entries.removeAll { $0.id == entry.id }
        saveEntries()
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
