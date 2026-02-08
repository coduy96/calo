import Foundation
import SwiftUI

@Observable
class WeightStore {
    private(set) var entries: [WeightEntry] = []

    private let storageKey = "weightEntries"

    init() {
        loadEntries()
        if entries.isEmpty {
            let profile = UserProfile.load() ?? .default
            let seed = WeightEntry(date: .now, weightKg: profile.weightKg)
            entries.append(seed)
            saveEntries()
        }
    }

    var latestEntry: WeightEntry? {
        entries.sorted { $0.date > $1.date }.first
    }

    func entries(in range: ClosedRange<Date>) -> [WeightEntry] {
        entries
            .filter { range.contains($0.date) }
            .sorted { $0.date < $1.date }
    }

    func addEntry(_ entry: WeightEntry) {
        entries.append(entry)
        saveEntries()

        // Sync weight to UserProfile so BMR/TDEE/macros recalculate
        if var profile = UserProfile.load() {
            profile.weightKg = entry.weightKg
            profile.save()
        }
    }

    func deleteEntry(_ entry: WeightEntry) {
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
              let decoded = try? JSONDecoder().decode([WeightEntry].self, from: data)
        else { return }
        entries = decoded
    }
}
