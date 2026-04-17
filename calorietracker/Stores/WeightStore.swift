import Foundation
import SwiftUI

@Observable
class WeightStore {
    private(set) var entries: [WeightEntry] = []
    var onEntryAdded: ((WeightEntry) -> Void)?
    var onEntryDeleted: ((UUID) -> Void)?

    private let storageKey = "weightEntries"

    init() {
        // Only seed a starter entry on a FRESH install (no storage key yet).
        // If the user has ever logged and later deleted everything, the key exists
        // (pointing to an empty array) and we must respect that — don't resurrect.
        let isFreshInstall = UserDefaults.standard.data(forKey: storageKey) == nil
        loadEntries()
        if entries.isEmpty && isFreshInstall {
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

        syncProfileWeightToLatest()

        // Detect goal-weight crossing — fire only on the transition, not on every weight past goal.
        if let profile = UserProfile.load(), let goalKg = profile.goalWeightKg, let previous = previousLatest {
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

    func deleteEntry(_ entry: WeightEntry) {
        let id = entry.id
        entries.removeAll { $0.id == id }
        saveEntries()
        onEntryDeleted?(id)
        syncProfileWeightToLatest()
    }

    /// Keep UserProfile.weightKg aligned with the most recent weight entry so Settings (Weight row)
    /// and Progress (Current badge) never disagree. If the store is empty, leave the profile as-is
    /// — we still need some weightKg for BMR/TDEE math; user can log a new one.
    private func syncProfileWeightToLatest() {
        guard var profile = UserProfile.load(),
              let newest = entries.sorted(by: { $0.date > $1.date }).first else { return }
        if abs(profile.weightKg - newest.weightKg) > 0.01 {
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
