package com.apoorvdarshan.calorietracker.ui.theme

import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable
import androidx.compose.ui.graphics.Color

/**
 * iOS system semantic colors — verbatim hex values from skiptools/skip-ui
 * (Sources/SkipUI/SkipUI/Color/Color.swift). Each color has distinct light + dark
 * variants matching what UIKit / SwiftUI resolves `.systemBlue` / `.red` / etc. to
 * on an iPhone. Read them from Compose code via `IOSColors.systemPink()` etc.
 *
 * Why this matters: Material 3's default palette doesn't match Apple's, so using
 * it everywhere makes Android look "off" when put next to iOS. These give us the
 * real iOS hex per color-mode.
 */
object IOSColors {
    @Composable @ReadOnlyComposable
    private fun pick(light: Long, dark: Long): Color =
        if (isSystemInDarkTheme()) Color(dark) else Color(light)

    // Neutral
    @Composable @ReadOnlyComposable fun gray(): Color = pick(0xFF8E8E93, 0xFF8E8E93)
    @Composable @ReadOnlyComposable fun gray2(): Color = pick(0xFFAEAEB2, 0xFF636366)
    @Composable @ReadOnlyComposable fun gray3(): Color = pick(0xFFC7C7CC, 0xFF48484A)
    @Composable @ReadOnlyComposable fun gray4(): Color = pick(0xFFD1D1D6, 0xFF3A3A3C)
    @Composable @ReadOnlyComposable fun gray5(): Color = pick(0xFFE5E5EA, 0xFF2C2C2E)
    @Composable @ReadOnlyComposable fun gray6(): Color = pick(0xFFF2F2F7, 0xFF1C1C1E)

    // System palette — all exact Apple values
    @Composable @ReadOnlyComposable fun systemRed(): Color = pick(0xFFFF3B30, 0xFFFF453A)
    @Composable @ReadOnlyComposable fun systemOrange(): Color = pick(0xFFFF9500, 0xFFFF9F0A)
    @Composable @ReadOnlyComposable fun systemYellow(): Color = pick(0xFFFFCC00, 0xFFFFD60A)
    @Composable @ReadOnlyComposable fun systemGreen(): Color = pick(0xFF34C759, 0xFF30D158)
    @Composable @ReadOnlyComposable fun systemMint(): Color = pick(0xFF00C7BE, 0xFF63E6E2)
    @Composable @ReadOnlyComposable fun systemTeal(): Color = pick(0xFF30B0C7, 0xFF40C8E0)
    @Composable @ReadOnlyComposable fun systemCyan(): Color = pick(0xFF32ADE6, 0xFF64D2FF)
    @Composable @ReadOnlyComposable fun systemBlue(): Color = pick(0xFF007AFF, 0xFF0A84FF)
    @Composable @ReadOnlyComposable fun systemIndigo(): Color = pick(0xFF5856D6, 0xFF5E5CE6)
    @Composable @ReadOnlyComposable fun systemPurple(): Color = pick(0xFFAF52DE, 0xFFBF5AF2)
    @Composable @ReadOnlyComposable fun systemPink(): Color = pick(0xFFFF2D55, 0xFFFF375F)
    @Composable @ReadOnlyComposable fun systemBrown(): Color = pick(0xFFA2845E, 0xFFAC8E68)

    // UIKit-style background layers — iOS dark mode backgrounds ARE NOT pure black
    @Composable @ReadOnlyComposable fun systemBackground(): Color = pick(0xFFFFFFFF, 0xFF000000)
    @Composable @ReadOnlyComposable fun secondarySystemBackground(): Color = pick(0xFFF2F2F7, 0xFF1C1C1E)
    @Composable @ReadOnlyComposable fun tertiarySystemBackground(): Color = pick(0xFFFFFFFF, 0xFF2C2C2E)

    // Grouped backgrounds — used by List / Section (.insetGroupedListStyle)
    @Composable @ReadOnlyComposable fun systemGroupedBackground(): Color = pick(0xFFF2F2F7, 0xFF000000)
    @Composable @ReadOnlyComposable fun secondarySystemGroupedBackground(): Color = pick(0xFFFFFFFF, 0xFF1C1C1E)
    @Composable @ReadOnlyComposable fun tertiarySystemGroupedBackground(): Color = pick(0xFFF2F2F7, 0xFF2C2C2E)

    // Separators — exact SwiftUI Color.secondary / Color.tertiary
    @Composable @ReadOnlyComposable fun separator(): Color = pick(0x4D3C3C43, 0x99545458) // 0.29 / 0.6 alpha on 3C3C43 / 545458
    @Composable @ReadOnlyComposable fun opaqueSeparator(): Color = pick(0xFFC6C6C8, 0xFF38383A)

    // Label colors — what SwiftUI .primary / .secondary / .tertiary resolve to
    @Composable @ReadOnlyComposable fun label(): Color = pick(0xFF000000, 0xFFFFFFFF)
    @Composable @ReadOnlyComposable fun secondaryLabel(): Color = pick(0x993C3C43, 0x99EBEBF5)
    @Composable @ReadOnlyComposable fun tertiaryLabel(): Color = pick(0x4D3C3C43, 0x4DEBEBF5)
    @Composable @ReadOnlyComposable fun quaternaryLabel(): Color = pick(0x2E3C3C43, 0x2EEBEBF5)
}
