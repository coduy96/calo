import Foundation

struct APIKeyManager {
    static func geminiAPIKey() -> String? {
        guard let url = Bundle.main.url(forResource: "Secrets", withExtension: "plist"),
              let data = try? Data(contentsOf: url),
              let plist = try? PropertyListSerialization.propertyList(from: data, format: nil) as? [String: Any],
              let key = plist["GEMINI_API_KEY"] as? String,
              key != "YOUR_API_KEY_HERE"
        else {
            return nil
        }
        return key
    }
}
