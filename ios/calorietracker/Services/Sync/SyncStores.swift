import Foundation

/// Bundles the live store instances the coordinator reads from / writes to.
@MainActor
struct SyncStores {
    let food: FoodStore
    let weight: WeightStore
    let bodyFat: BodyFatStore
    let chat: ChatStore
    // Profile is a singleton via UserProfile.load()/save(); no store ref needed.
}
