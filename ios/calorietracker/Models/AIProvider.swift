import Foundation

/// Anonymous device identity + backend URL config + entitlement cache. This
/// is the only client-side state that ties an install to the user's
/// subscription. RevenueCat receives `installID` as its `appUserID`; the
/// backend keys entitlement rows on the same value.
enum AppIdentity {
    private static let installIDKey = "voidpenInstallID"
    private static let plusEntitlementCacheKey = "voidpenPlusEntitlementCached"

    /// Stable per-install UUID. Persisted in UserDefaults; never reset except
    /// by the user uninstalling. New installs get a fresh UUID — restoring a
    /// previous purchase triggers a RevenueCat TRANSFER webhook that moves
    /// the entitlement row to the new install_id.
    static var installID: String {
        if let existing = UserDefaults.standard.string(forKey: installIDKey), !existing.isEmpty {
            return existing
        }
        let newID = UUID().uuidString
        UserDefaults.standard.set(newID, forKey: installIDKey)
        return newID
    }

    /// Cached "is the user entitled?" flag. The source of truth is RevenueCat
    /// (queried at launch + after every purchase / restore); this cache lets
    /// the UI gate without going async on every render.
    static var hasActiveEntitlement: Bool {
        UserDefaults.standard.bool(forKey: plusEntitlementCacheKey)
    }

    static func setActiveEntitlement(_ active: Bool) {
        UserDefaults.standard.set(active, forKey: plusEntitlementCacheKey)
    }
}

/// Backend URL helper. Reads `VoidpenBackendURL` from Info.plist (set via the
/// build settings) so dev / prod can point at different projects. The anon
/// key is sent as both `apikey` and `Authorization: Bearer` headers so
/// Supabase's edge gateway accepts the request.
enum BackendConfig {
    private static let backendURLKey = "VoidpenBackendURL"
    private static let backendAnonKeyKey = "VoidpenBackendAnonKey"

    static var baseURL: URL? {
        let raw = (Bundle.main.object(forInfoDictionaryKey: backendURLKey) as? String) ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains("$(") else { return nil }
        return URL(string: trimmed)
    }

    static var anonKey: String? {
        let raw = (Bundle.main.object(forInfoDictionaryKey: backendAnonKeyKey) as? String) ?? ""
        let trimmed = raw.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty, !trimmed.contains("$(") else { return nil }
        return trimmed
    }

    /// Construct `<base>/api/<path>`. The `api` Edge Function fronts every
    /// LLM endpoint (generate, transcribe).
    static func url(for path: String) -> URL? {
        guard let baseURL else { return nil }
        return baseURL.appendingPathComponent("functions/v1/api/").appendingPathComponent(path)
    }
}
