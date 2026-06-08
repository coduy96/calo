import Foundation

/// The kinds of records Voidpen syncs. Each maps to a CloudKit record type and
/// a recordName prefix so the same UUID can exist as two kinds (e.g. a logged
/// food entry and a favorite) without colliding on CKRecord.ID.
enum SyncRecordKind: String, CaseIterable {
    case food, favorite, weight, bodyFat, chat, profile

    var recordType: String {
        switch self {
        case .food:     return "FoodEntry"
        case .favorite: return "FoodFavorite"
        case .weight:   return "WeightEntry"
        case .bodyFat:  return "BodyFatEntry"
        case .chat:     return "ChatThread"
        case .profile:  return "UserProfile"
        }
    }

    var prefix: String {
        switch self {
        case .food:     return "food_"
        case .favorite: return "fav_"
        case .weight:   return "weight_"
        case .bodyFat:  return "bodyfat_"
        case .chat:     return "chat_"
        case .profile:  return "profile"
        }
    }

    /// The profile is a singleton with a fixed recordName.
    var fixedRecordName: String { "profile" }

    func recordName(for id: UUID) -> String {
        self == .profile ? fixedRecordName : "\(prefix)\(id.uuidString)"
    }

    static func kind(forRecordType recordType: String) -> SyncRecordKind? {
        allCases.first { $0.recordType == recordType }
    }

    /// Parse a recordName back into (kind, id). Returns nil for the profile
    /// singleton (use kind(forRecordType:) there) or malformed names.
    static func parse(recordName: String) -> (kind: SyncRecordKind, id: UUID)? {
        for kind in allCases where kind != .profile {
            if recordName.hasPrefix(kind.prefix),
               let id = UUID(uuidString: String(recordName.dropFirst(kind.prefix.count))) {
                return (kind, id)
            }
        }
        return nil
    }
}

/// A local change a store reports outbound to the sync coordinator.
struct SyncMutation {
    let kind: SyncRecordKind
    let id: UUID
    let deleted: Bool
}
