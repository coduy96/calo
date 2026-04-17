import Foundation
import SwiftUI

@Observable
class WeightStore {
    private(set) var entries: [WeightEntry] = []
    var onEntryAdded: ((WeightEntry) -> Void)?
    var onEntryDeleted: ((UUID) -> Void)?

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
        let previousLatest = entries.sorted { $0.date > $1.date }.first
        entries.append(entry)
        saveEntries()
        onEntryAdded?(entry)

        // Sync weight to UserProfile (formula-derived numbers update; custom goals stay locked).
        if var profile = UserProfile.load() {
            profile.weightKg = entry.weightKg
            profile.save()

            // Detect goal-weight crossing — fire only on the transition, not on every weight past goal.
            if let goalKg = profile.goalWeightKg, let previous = previousLatest {
                let crossed: Bool
                switch profile.goal {
                case .lose:    crossed = previous.weightKg > goalKg && entry.weightKg <= goalKg
                case .gain:    crossed = previous.weightKg < goalKg && entry.weightKg >= goalKg
                case .maintain: crossed = false
                }
                if crossed {
                    NotificationCenter.default.post(name: .weightGoalReached, object: nil)
                }
            }
        }
    }

    func deleteEntry(_ entry: WeightEntry) {
        let id = entry.id
        entries.removeAll { $0.id == id }
        saveEntries()
        onEntryDeleted?(id)

        // Sync remaining latest weight back to UserProfile so the rest of the app stays consistent.
        if var profile = UserProfile.load(), let newest = entries.sorted(by: { $0.date > $1.date }).first {
            profile.weightKg = newest.weightKg
            profile.save()
        }
    }

    func replaceAllEntries(_ newEntries: [WeightEntry]) {
        entries = newEntries
        saveEntries()
    }

    func mergeWithCloudEntries(_ cloudEntries: [WeightEntry]) {
        var merged = Dictionary(uniqueKeysWithValues: entries.map { ($0.id, $0) })
        for cloudEntry in cloudEntries {
            merged[cloudEntry.id] = cloudEntry
        }
        entries = Array(merged.values)
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
