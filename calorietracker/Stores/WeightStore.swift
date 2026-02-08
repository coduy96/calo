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
        if UserDefaults.standard.string(forKey: "appleUserID") != nil {
            Task { await CloudKitService.saveWeightEntry(entry) }
        }
    }

    func deleteEntry(_ entry: WeightEntry) {
        let id = entry.id
        entries.removeAll { $0.id == id }
        saveEntries()
        if UserDefaults.standard.string(forKey: "appleUserID") != nil {
            Task { await CloudKitService.deleteWeightEntry(id: id) }
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
