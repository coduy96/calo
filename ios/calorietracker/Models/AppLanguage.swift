import Foundation

/// User-selectable display language for the app's UI. `.system` defers to the
/// device's language priority list; every other case pins the app to a single
/// localization regardless of the device language.
///
/// The raw value doubles as the persisted `@AppStorage("appLanguage")` value
/// and the language code written into the `AppleLanguages` UserDefaults key.
enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case english = "en"
    case vietnamese = "vi"
    case arabic = "ar"
    case azerbaijani = "az"
    case german = "de"
    case spanish = "es"
    case french = "fr"
    case hindi = "hi"
    case italian = "it"
    case japanese = "ja"
    case korean = "ko"
    case dutch = "nl"
    case portugueseBR = "pt-BR"
    case romanian = "ro"
    case russian = "ru"
    case simplifiedChinese = "zh-Hans"

    var id: String { rawValue }

    /// Shown in the picker. Each language is rendered in its own native form so
    /// a user who can't read the current UI language can still find their own.
    var displayName: String {
        switch self {
        case .system: return String(localized: "System")
        case .english: return "English"
        case .vietnamese: return "Tiếng Việt"
        case .arabic: return "العربية"
        case .azerbaijani: return "Azərbaycan"
        case .german: return "Deutsch"
        case .spanish: return "Español"
        case .french: return "Français"
        case .hindi: return "हिन्दी"
        case .italian: return "Italiano"
        case .japanese: return "日本語"
        case .korean: return "한국어"
        case .dutch: return "Nederlands"
        case .portugueseBR: return "Português (Brasil)"
        case .romanian: return "Română"
        case .russian: return "Русский"
        case .simplifiedChinese: return "简体中文"
        }
    }

    /// English name of this language, suitable for embedding in an LLM prompt
    /// (e.g. "Respond in Vietnamese."). Gemini reliably understands the English
    /// names of languages even when the user has the rest of the app in a
    /// different locale. `.system` resolves to whatever the device's current
    /// preferred localization is.
    var promptLanguageName: String {
        switch self {
        case .system:
            let code = Locale.current.language.languageCode?.identifier ?? "en"
            let region = Locale.current.language.region?.identifier
            let composed = region.map { "\(code)-\($0)" } ?? code
            let englishLocale = Locale(identifier: "en")
            return englishLocale.localizedString(forIdentifier: composed)
                ?? englishLocale.localizedString(forLanguageCode: code)
                ?? "English"
        case .english: return "English"
        case .vietnamese: return "Vietnamese"
        case .arabic: return "Arabic"
        case .azerbaijani: return "Azerbaijani"
        case .german: return "German"
        case .spanish: return "Spanish"
        case .french: return "French"
        case .hindi: return "Hindi"
        case .italian: return "Italian"
        case .japanese: return "Japanese"
        case .korean: return "Korean"
        case .dutch: return "Dutch"
        case .portugueseBR: return "Brazilian Portuguese"
        case .romanian: return "Romanian"
        case .russian: return "Russian"
        case .simplifiedChinese: return "Simplified Chinese"
        }
    }
}

enum AppLanguageSettings {
    static let storageKey = "appLanguage"
    /// UserDefaults key Foundation reads at process launch to pick the bundle
    /// localization. Writing to it from inside the running process does not
    /// re-localize already-loaded views — the app must be relaunched.
    static let appleLanguagesKey = "AppleLanguages"

    /// Reads the user's choice. Falls back to `.system` if nothing stored or
    /// the stored value is unknown (e.g. a localization was removed in an
    /// app update).
    static var current: AppLanguage {
        let raw = UserDefaults.standard.string(forKey: storageKey) ?? ""
        return AppLanguage(rawValue: raw) ?? .system
    }

    /// Applies the user's stored preference to Foundation's `AppleLanguages`
    /// list. Must run before any SwiftUI view loads — i.e. from `App.init()` —
    /// otherwise the bundle has already cached its localization for this
    /// process and the override only takes effect on next launch.
    ///
    /// For `.system` we remove the override entirely so iOS goes back to using
    /// the device's language priority list instead of pinning to one entry.
    static func applyToBundle() {
        let lang = current
        switch lang {
        case .system:
            UserDefaults.standard.removeObject(forKey: appleLanguagesKey)
        default:
            UserDefaults.standard.set([lang.rawValue], forKey: appleLanguagesKey)
        }
    }
}
