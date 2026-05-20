import Foundation
import StoreKit
import SwiftUI

/// Owns the once-per-install gate for the native App Store review prompt.
/// Trigger: the user logs at least one entry of each of .breakfast, .lunch,
/// and .dinner on the same day — the first moment they've completed a full
/// day in the app and are most likely to feel positive about it.
@Observable
final class ReviewPromptManager {
    private static let flagKey = "hasRequestedAppReview"

    private var hasRequested: Bool {
        get { UserDefaults.standard.bool(forKey: Self.flagKey) }
        set { UserDefaults.standard.set(newValue, forKey: Self.flagKey) }
    }

    func evaluateAndPromptIfEligible(foodStore: FoodStore) {
        guard !hasRequested else { return }

        let todayEntries = foodStore.entries(for: .now)
        let mealTypes = Set(todayEntries.map { $0.mealType })
        let required: [MealType] = [.breakfast, .lunch, .dinner]
        guard required.allSatisfy({ mealTypes.contains($0) }) else { return }

        // Set the flag synchronously so a burst of adds in the same runloop
        // can't double-fire the prompt before the delayed block runs.
        hasRequested = true

        DispatchQueue.main.asyncAfter(deadline: .now() + 0.7) {
            guard let scene = UIApplication.shared.connectedScenes
                .first(where: { $0.activationState == .foregroundActive }) as? UIWindowScene
            else { return }
            AppStore.requestReview(in: scene)
        }
    }

    #if DEBUG
    /// Clears the once-per-install flag so the prompt can be re-triggered
    /// during simulator testing. Not exposed in production UI.
    func resetReviewPromptFlag() {
        UserDefaults.standard.removeObject(forKey: Self.flagKey)
    }
    #endif
}
