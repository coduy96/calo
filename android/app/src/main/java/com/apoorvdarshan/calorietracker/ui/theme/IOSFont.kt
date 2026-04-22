package com.apoorvdarshan.calorietracker.ui.theme

import androidx.compose.ui.text.TextStyle
import androidx.compose.ui.text.font.FontFamily
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.sp

/**
 * iOS Dynamic Type scale mapped to sp. Values match UIKit's default
 * (non-accessibility) sizes for each text style. Modeled on the same
 * approach Skip uses in skip-ui: treat iOS text styles as the source
 * of truth and normalize Compose to them instead of the other way around.
 *
 * Weights come from iOS defaults (headline is semibold, body is regular, etc).
 * Line heights match iOS too, e.g. body 22, headline 22, caption 16.
 */
object IOSFont {
    private val family = FontFamily.Default

    val largeTitle = TextStyle(fontFamily = family, fontSize = 34.sp, lineHeight = 41.sp, fontWeight = FontWeight.Bold)
    val title      = TextStyle(fontFamily = family, fontSize = 28.sp, lineHeight = 34.sp, fontWeight = FontWeight.Bold)
    val title2     = TextStyle(fontFamily = family, fontSize = 22.sp, lineHeight = 28.sp, fontWeight = FontWeight.SemiBold)
    val title3     = TextStyle(fontFamily = family, fontSize = 20.sp, lineHeight = 25.sp, fontWeight = FontWeight.SemiBold)
    val headline   = TextStyle(fontFamily = family, fontSize = 17.sp, lineHeight = 22.sp, fontWeight = FontWeight.SemiBold)
    val body       = TextStyle(fontFamily = family, fontSize = 17.sp, lineHeight = 22.sp, fontWeight = FontWeight.Normal)
    val bodyBold   = body.copy(fontWeight = FontWeight.SemiBold)
    val callout    = TextStyle(fontFamily = family, fontSize = 16.sp, lineHeight = 21.sp, fontWeight = FontWeight.Normal)
    val subheadline= TextStyle(fontFamily = family, fontSize = 15.sp, lineHeight = 20.sp, fontWeight = FontWeight.Normal)
    val footnote   = TextStyle(fontFamily = family, fontSize = 13.sp, lineHeight = 18.sp, fontWeight = FontWeight.Normal)
    val caption    = TextStyle(fontFamily = family, fontSize = 12.sp, lineHeight = 16.sp, fontWeight = FontWeight.Normal)
    val caption2   = TextStyle(fontFamily = family, fontSize = 11.sp, lineHeight = 13.sp, fontWeight = FontWeight.Normal)

    // Extra-large display sizes used in Fud AI iOS (e.g. the 72pt calorie hero)
    val heroNumber = TextStyle(fontFamily = family, fontSize = 72.sp, lineHeight = 76.sp, fontWeight = FontWeight.Bold)
}
