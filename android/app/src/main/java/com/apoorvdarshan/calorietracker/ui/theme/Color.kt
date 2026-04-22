package com.apoorvdarshan.calorietracker.ui.theme

import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color

/**
 * Fud AI accent gradient. The base hex is Apple's systemPink dark-mode value
 * (0xFFFF375F) — matching the iOS app. The second stop is a brighter
 * highlight that matches the iOS LinearGradient used for the hero number
 * and macro progress bars.
 *
 * For iOS system semantic colors (systemBlue, systemGreen, etc.) use
 * [IOSColors] instead of this file.
 */
object AppColors {
    // iOS systemPink (dark) — matches the iOS Fud AI accent exactly
    val CalorieStart = Color(0xFFFF375F)
    val CalorieEnd = Color(0xFFFF6B8A)

    val Calorie = CalorieStart
    val Protein = CalorieStart
    val Carbs = CalorieStart
    val Fat = CalorieStart

    val CalorieGradient = Brush.linearGradient(listOf(CalorieStart, CalorieEnd))

    // Legacy tokens retained so existing call sites don't break. Prefer
    // IOSColors.systemBackground() / secondarySystemGroupedBackground() in
    // new code — those are the Apple-correct Light/Dark pair per semantic slot.
    val AppBackgroundLight = Color(0xFFF2F2F7)
    val AppBackgroundDark = Color(0xFF000000)

    val AppCardLight = Color(0xFFFFFFFF)
    val AppCardDark = Color(0xFF1C1C1E)

    val OnLight = Color(0xFF000000)
    val OnDark = Color(0xFFFFFFFF)

    val MutedLight = Color(0xFF8E8E93)
    val MutedDark = Color(0xFF8E8E93)

    val DividerLight = Color(0xFFC6C6C8)
    val DividerDark = Color(0xFF38383A)
}
