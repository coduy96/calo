import SwiftUI

enum AppColors {
    // Calorie: Red → Pink
    static let calorieGradient: [Color] = [Color(hex: 0xFF375F), Color(hex: 0xFF6B8A)]
    static let calorie: Color = Color(hex: 0xFF375F)

    // Protein: Rose → Light Pink
    static let proteinGradient: [Color] = [Color(hex: 0xE8608C), Color(hex: 0xF5A0B8)]
    static let protein: Color = Color(hex: 0xE8608C)

    // Carbs: Mauve → Lavender Pink
    static let carbsGradient: [Color] = [Color(hex: 0xC47AB8), Color(hex: 0xE0A8D6)]
    static let carbs: Color = Color(hex: 0xC47AB8)

    // Fat: Dusty Rose → Blush
    static let fatGradient: [Color] = [Color(hex: 0xD47C8A), Color(hex: 0xEDB3BD)]
    static let fat: Color = Color(hex: 0xD47C8A)

    // Background: warm cream in light, system dark in dark
    static let appBackground = Color("appBackground")
    static let appCard = Color("appCard")
}

extension Color {
    init(hex: UInt, opacity: Double = 1.0) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255,
            opacity: opacity
        )
    }
}
