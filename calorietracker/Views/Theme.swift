import SwiftUI

enum AppColors {
    // Calorie: Red → Pink
    static let calorieGradient: [Color] = [Color(hex: 0xFF375F), Color(hex: 0xFF6B8A)]
    static let calorie: Color = Color(hex: 0xFF375F)

    // Protein
    static let proteinGradient: [Color] = calorieGradient
    static let protein: Color = calorie

    // Carbs
    static let carbsGradient: [Color] = calorieGradient
    static let carbs: Color = calorie

    // Fat
    static let fatGradient: [Color] = calorieGradient
    static let fat: Color = calorie

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
