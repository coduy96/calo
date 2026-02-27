import Foundation
import SwiftUI

@Observable
class WeightStore {
    private(set) var entries: [WeightEntry] = []
    var onEntryAdded: ((WeightEntry) -> Void)?

    private let storageKey = "weightEntries"

    init() {
        loadEntries()
        if entries.isEmpty {
            #if DEBUG
            seedDebugData()
            #else
            let profile = UserProfile.load() ?? .default
            let seed = WeightEntry(date: .now, weightKg: profile.weightKg)
            entries.append(seed)
            #endif
            saveEntries()
        }
    }

    #if DEBUG
    private func seedDebugData() {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: .now)
        let startKg = 85.0
        // ~90 days of data, losing ~0.5 kg/week with some noise
        for dayOffset in stride(from: 90, through: 0, by: -3) {
            guard let date = calendar.date(byAdding: .day, value: -dayOffset, to: today) else { continue }
            let weeksElapsed = Double(90 - dayOffset) / 7.0
            let trend = startKg - weeksElapsed * 0.5
            let noise = Double.random(in: -0.4...0.4)
            let weight = max(trend + noise, 60)
            entries.append(WeightEntry(date: date, weightKg: weight))
        }
    }
    #endif

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
        onEntryAdded?(entry)

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
