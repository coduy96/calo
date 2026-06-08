import Foundation
import SwiftUI

@Observable
class WeightStore {
    private(set) var entries: [WeightEntry] = []
    var onEntryAdded: ((WeightEntry) -> Void)?
    var onEntryDeleted: ((UUID) -> Void)?
    var onSyncMutation: ((SyncMutation) -> Void)?

    private let storageKey = "weightEntries"

    init() {
        loadEntries()
        // No default seed — WeightStore.init runs before onboarding finishes on a fresh
        // install, so `UserProfile.load()` is nil and the old seed fell back to .default
        // (70 kg), dropping a phantom 70 kg entry onto every new user's chart even if
        // their real weight was different. Onboarding now seeds the first WeightEntry
        // via `seedInitialWeightFromProfileIfEmpty(_:)` once the profile is real.
    }

    /// Add the first WeightEntry from the user's onboarding-set profile weight.
    /// Safe to call multiple times — no-op if any entries already exist, so subsequent
    /// scene-active firings or re-onboarding paths can't duplicate.
    func seedInitialWeightFromProfileIfEmpty(_ weightKg: Double) {
        guard entries.isEmpty else { return }
        addEntry(WeightEntry(date: .now, weightKg: weightKg))
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
        var entry = entry
        entry.modifiedAt = Date()
        let previousLatest = entries.sorted { $0.date > $1.date }.first
        entries.append(entry)
        saveEntries()
        onEntryAdded?(entry)
        onSyncMutation?(SyncMutation(kind: .weight, id: entry.id, deleted: false))

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
        if let filename = entry.photoFilename {
            WeightPhotoStore.shared.delete(filename: filename)
        }
        saveEntries()
        onEntryDeleted?(id)
        onSyncMutation?(SyncMutation(kind: .weight, id: id, deleted: true))
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

    /// Bulk-import weight samples discovered from HealthKit (e.g. years of
    /// scale history that predate Voidpen). Bypasses onEntryAdded so the
    /// imported externals don't echo back to HK as fresh writes — these
    /// samples already exist there. Saves + syncs profile once at the end.
    func importExternalEntries(_ external: [WeightEntry]) {
        guard !external.isEmpty else { return }
        entries.append(contentsOf: external)
        saveEntries()
        syncProfileWeightToLatest()
    }

    // MARK: - Cloud inbound (no echo, LWW)

    func applyCloudUpsert(_ incoming: WeightEntry) {
        if let idx = entries.firstIndex(where: { $0.id == incoming.id }) {
            guard incoming.effectiveModifiedAt >= entries[idx].effectiveModifiedAt else { return }
            entries[idx] = incoming
        } else {
            entries.append(incoming)
        }
        saveEntries()
    }

    func applyCloudDelete(id: UUID) {
        guard let entry = entries.first(where: { $0.id == id }) else { return }
        if let filename = entry.photoFilename { WeightPhotoStore.shared.delete(filename: filename) }
        entries.removeAll { $0.id == id }
        saveEntries()
    }

    private func saveEntries() {
        if let data = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(data, forKey: storageKey)
        }
    }

    /// Re-read entries from UserDefaults. Used after MockDataSeeder rewrites
    /// the store key so the live @State instance picks up the new data.
    func reloadFromDisk() {
        entries = []
        loadEntries()
    }

    private func loadEntries() {
        guard let data = UserDefaults.standard.data(forKey: storageKey),
              let decoded = try? JSONDecoder().decode([WeightEntry].self, from: data)
        else { return }
        entries = decoded
    }
}
