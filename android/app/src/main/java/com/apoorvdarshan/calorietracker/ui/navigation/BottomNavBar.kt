package com.apoorvdarshan.calorietracker.ui.navigation

import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateDpAsState
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.BoxWithConstraints
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.offset
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.BarChart
import androidx.compose.material.icons.filled.Forum
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.Info
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.apoorvdarshan.calorietracker.ui.theme.AppColors

data class BottomTab(val route: String, val icon: ImageVector, val label: String)

val BottomTabs = listOf(
    BottomTab(FudAIRoutes.HOME, Icons.Filled.Home, "Home"),
    BottomTab(FudAIRoutes.PROGRESS, Icons.Filled.BarChart, "Progress"),
    BottomTab(FudAIRoutes.COACH, Icons.Filled.Forum, "Coach"),
    BottomTab(FudAIRoutes.SETTINGS, Icons.Filled.Settings, "Settings"),
    BottomTab(FudAIRoutes.ABOUT, Icons.Filled.Info, "About")
)

/**
 * Floating Liquid Glass tab bar — capsule with translucent backdrop, hairline
 * border, soft shadow, and a spring-animated pill highlight that slides
 * behind the active tab.
 *
 * Approximates iOS 26 Liquid Glass via:
 *   - dark / light translucent surface (works against any background)
 *   - top-light → bottom-dark vertical sheen overlay (glass refraction stand-in)
 *   - hairline white-gradient border
 *   - 18dp ambient + spot shadow for floating depth
 *   - spring-animated translateX on the active-tab pill highlight
 *   - subtle scale bump on the selected icon
 */
@Composable
fun FudAIBottomNavBar(
    currentRoute: String?,
    onTap: (String) -> Unit,
    modifier: Modifier = Modifier
) {
    val isDark = MaterialTheme.colorScheme.background.let {
        (it.red + it.green + it.blue) / 3f < 0.5f
    }

    val barShape = RoundedCornerShape(34.dp)

    val backdropColor = if (isDark) Color(0xFF1A1A1C).copy(alpha = 0.92f)
                        else Color(0xFFFFFFFF).copy(alpha = 0.92f)

    val sheenBrush = Brush.verticalGradient(
        colors = if (isDark)
            listOf(Color.White.copy(alpha = 0.10f), Color.White.copy(alpha = 0.0f))
        else
            listOf(Color.White.copy(alpha = 0.55f), Color.White.copy(alpha = 0.15f))
    )

    val borderBrush = Brush.linearGradient(
        listOf(
            Color.White.copy(alpha = if (isDark) 0.22f else 0.65f),
            Color.White.copy(alpha = if (isDark) 0.04f else 0.18f)
        )
    )

    val highlightColor = if (isDark) Color.White.copy(alpha = 0.10f)
                         else AppColors.Calorie.copy(alpha = 0.12f)

    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 14.dp, vertical = 10.dp)
    ) {
        BoxWithConstraints(
            Modifier
                .fillMaxWidth()
                .height(68.dp)
                .shadow(
                    elevation = 18.dp,
                    shape = barShape,
                    ambientColor = Color.Black.copy(alpha = 0.30f),
                    spotColor = Color.Black.copy(alpha = 0.30f)
                )
                .clip(barShape)
                .background(backdropColor)
                .background(sheenBrush)
                .border(0.8.dp, borderBrush, barShape)
        ) {
            val barWidthDp = maxWidth
            val tabCount = BottomTabs.size
            val tabWidthDp = barWidthDp / tabCount
            val selectedIndex = BottomTabs.indexOfFirst { it.route == currentRoute }
                .coerceAtLeast(0)

            val highlightOffset by animateDpAsState(
                targetValue = tabWidthDp * selectedIndex,
                animationSpec = spring(
                    dampingRatio = Spring.DampingRatioLowBouncy,
                    stiffness = 320f
                ),
                label = "tabHighlightOffset"
            )

            // Active-tab pill highlight — slides with spring animation.
            Box(
                Modifier
                    .offset(x = highlightOffset)
                    .width(tabWidthDp)
                    .fillMaxHeight()
                    .padding(horizontal = 6.dp, vertical = 8.dp)
                    .clip(RoundedCornerShape(22.dp))
                    .background(highlightColor)
            )

            Row(
                Modifier.fillMaxWidth().fillMaxHeight(),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically
            ) {
                for (tab in BottomTabs) {
                    val selected = tab.route == currentRoute
                    TabItem(
                        tab = tab,
                        selected = selected,
                        isDark = isDark,
                        modifier = Modifier.width(tabWidthDp).fillMaxHeight()
                    ) { onTap(tab.route) }
                }
            }
        }
    }
}

@Composable
private fun TabItem(
    tab: BottomTab,
    selected: Boolean,
    isDark: Boolean,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    val activeColor = AppColors.Calorie
    val inactiveColor = if (isDark) Color.White.copy(alpha = 0.55f)
                        else Color.Black.copy(alpha = 0.55f)
    val tint = if (selected) activeColor else inactiveColor

    val iconScale by animateFloatAsState(
        targetValue = if (selected) 1.06f else 1.0f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = 380f
        ),
        label = "tabIconScale"
    )

    Column(
        modifier = modifier.clickable(
            interactionSource = MutableInteractionSource(),
            indication = null,
            onClick = onClick
        ),
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            tab.icon,
            contentDescription = tab.label,
            tint = tint,
            modifier = Modifier.size(24.dp).scale(iconScale)
        )
        Spacer(Modifier.height(3.dp))
        Text(
            tab.label,
            color = tint,
            fontSize = 10.5.sp,
            fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Medium
        )
    }
}
