package com.apoorvdarshan.calorietracker.ui.navigation

import androidx.compose.animation.core.Animatable
import androidx.compose.animation.core.Spring
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.spring
import androidx.compose.foundation.background
import androidx.compose.foundation.border
import androidx.compose.foundation.gestures.awaitEachGesture
import androidx.compose.foundation.gestures.awaitFirstDown
import androidx.compose.foundation.gestures.awaitHorizontalTouchSlopOrCancellation
import androidx.compose.foundation.gestures.horizontalDrag
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
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableFloatStateOf
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.draw.scale
import androidx.compose.ui.draw.shadow
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.TransformOrigin
import androidx.compose.ui.graphics.graphicsLayer
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.input.pointer.pointerInput
import androidx.compose.ui.input.pointer.positionChange
import androidx.compose.ui.platform.LocalDensity
import androidx.compose.ui.platform.LocalHapticFeedback
import androidx.compose.ui.hapticfeedback.HapticFeedbackType
import androidx.compose.ui.semantics.Role
import androidx.compose.ui.semantics.contentDescription
import androidx.compose.ui.semantics.onClick
import androidx.compose.ui.semantics.role
import androidx.compose.ui.semantics.selected
import androidx.compose.ui.semantics.semantics
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.apoorvdarshan.calorietracker.ui.theme.AppColors
import kotlinx.coroutines.launch

data class BottomTab(val route: String, val icon: ImageVector, val label: String)

val BottomTabs = listOf(
    BottomTab(FudAIRoutes.HOME, Icons.Filled.Home, "Home"),
    BottomTab(FudAIRoutes.PROGRESS, Icons.Filled.BarChart, "Progress"),
    BottomTab(FudAIRoutes.COACH, Icons.Filled.Forum, "Coach"),
    BottomTab(FudAIRoutes.SETTINGS, Icons.Filled.Settings, "Settings"),
    BottomTab(FudAIRoutes.ABOUT, Icons.Filled.Info, "About")
)

private val BarHeight = 72.dp
private val BarCorner = 36.dp
private val PillCorner = 26.dp
private val PillInsetH = 8.dp
private val PillInsetV = 6.dp

/**
 * Floating Liquid Glass tab bar — capsule with translucent backdrop, glassy
 * sheen, hairline border, soft shadow, and a spring-animated bright pill
 * behind the active tab.
 *
 * The pill is **draggable**: place a finger anywhere on the bar and slide
 * horizontally to drag it across tabs. Taps still work normally (drag is
 * only claimed after horizontal touch slop). On release the pill snaps to
 * the nearest tab; haptic ticks fire each time the pill crosses a boundary
 * during the drag, mirroring the iOS 26 Liquid Glass tab-bar feel.
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

    val barShape = RoundedCornerShape(BarCorner)

    val backdropColor = if (isDark) Color(0xFF15151A).copy(alpha = 0.86f)
                        else Color(0xFFFFFFFF).copy(alpha = 0.90f)

    val barSheen = Brush.verticalGradient(
        colors = if (isDark)
            listOf(Color.White.copy(alpha = 0.14f), Color.White.copy(alpha = 0.0f))
        else
            listOf(Color.White.copy(alpha = 0.55f), Color.White.copy(alpha = 0.10f))
    )

    val barBorder = Brush.linearGradient(
        listOf(
            Color.White.copy(alpha = if (isDark) 0.28f else 0.65f),
            Color.White.copy(alpha = if (isDark) 0.06f else 0.18f)
        )
    )

    Box(
        modifier = modifier
            .fillMaxWidth()
            .padding(horizontal = 14.dp, vertical = 10.dp)
    ) {
        BoxWithConstraints(
            Modifier
                .fillMaxWidth()
                .height(BarHeight)
                .shadow(
                    elevation = 22.dp,
                    shape = barShape,
                    ambientColor = Color.Black.copy(alpha = 0.35f),
                    spotColor = Color.Black.copy(alpha = 0.35f)
                )
                .clip(barShape)
                .background(backdropColor)
                .background(barSheen)
                .border(0.8.dp, barBorder, barShape)
        ) {
            val density = LocalDensity.current
            val haptic = LocalHapticFeedback.current
            val scope = rememberCoroutineScope()

            val barWidthDp = maxWidth
            val tabCount = BottomTabs.size
            val tabWidthDp = barWidthDp / tabCount
            val tabWidthPx = with(density) { tabWidthDp.toPx() }
            val maxOffsetPx = tabWidthPx * (tabCount - 1)

            val selectedIndex = BottomTabs.indexOfFirst { it.route == currentRoute }
                .coerceAtLeast(0)

            // Spring animator drives the pill when it's NOT being dragged
            // (initial mount, external route changes, settle-after-release).
            val pillAnim = remember { Animatable(0f) }
            var isDragging by remember { mutableStateOf(false) }
            var dragOffsetPx by remember { mutableFloatStateOf(0f) }
            var hoverIndex by remember { mutableIntStateOf(selectedIndex) }

            // Sync pill position once the bar's width has been measured, and on
            // any later external selectedIndex change. Skip while dragging so a
            // mid-drag recomposition doesn't yank the pill back to a snapped
            // position.
            LaunchedEffect(selectedIndex, tabWidthPx) {
                if (!isDragging) {
                    val target = selectedIndex * tabWidthPx
                    if (pillAnim.value == 0f && selectedIndex > 0) {
                        pillAnim.snapTo(target)
                    } else {
                        pillAnim.animateTo(
                            target,
                            spring(
                                dampingRatio = Spring.DampingRatioLowBouncy,
                                stiffness = 320f
                            )
                        )
                    }
                }
            }

            val pillPx = if (isDragging) dragOffsetPx else pillAnim.value
            val pillOffsetDp = with(density) { pillPx.toDp() }

            val pillScale by animateFloatAsState(
                targetValue = if (isDragging) 1.06f else 1f,
                animationSpec = spring(
                    dampingRatio = Spring.DampingRatioMediumBouncy,
                    stiffness = 380f
                ),
                label = "pillDragScale"
            )

            // Active-tab pill — the bright glass disc.
            ActivePill(
                tabWidth = tabWidthDp,
                isDark = isDark,
                modifier = Modifier
                    .offset(x = pillOffsetDp)
                    .graphicsLayer {
                        scaleX = pillScale
                        scaleY = pillScale
                        transformOrigin = TransformOrigin(0.5f, 0.5f)
                    }
            )

            // Visual tabs. Tap + drag are both handled by the overlay below;
            // the row exists for layout + a11y semantics only.
            Row(
                Modifier.fillMaxWidth().fillMaxHeight(),
                horizontalArrangement = Arrangement.SpaceEvenly,
                verticalAlignment = Alignment.CenterVertically
            ) {
                for ((idx, tab) in BottomTabs.withIndex()) {
                    val isSelected = tab.route == currentRoute
                    TabItem(
                        tab = tab,
                        selected = isSelected,
                        isDark = isDark,
                        modifier = Modifier
                            .width(tabWidthDp)
                            .fillMaxHeight()
                            .semantics {
                                role = Role.Tab
                                selected = isSelected
                                contentDescription = tab.label
                                onClick {
                                    if (BottomTabs[idx].route != currentRoute) {
                                        onTap(BottomTabs[idx].route)
                                    }
                                    true
                                }
                            }
                    )
                }
            }

            // Single gesture overlay that owns BOTH tap and horizontal drag.
            // A previous version kept clickable on TabItem and put only drag
            // on the overlay, but the overlay sits on top in z-order and
            // intercepts the down event, so the tab's click never fired.
            Box(
                Modifier
                    .matchParentSize()
                    .pointerInput(tabWidthPx, tabCount) {
                        if (tabWidthPx <= 0f) return@pointerInput
                        awaitEachGesture {
                            val down = awaitFirstDown(requireUnconsumed = false)
                            val dragChange = awaitHorizontalTouchSlopOrCancellation(down.id) { change, _ ->
                                change.consume()
                            }

                            if (dragChange == null) {
                                // No horizontal slop reached → treat as a tap
                                // on whichever tab the down landed in.
                                val tappedIdx = (down.position.x / tabWidthPx)
                                    .toInt().coerceIn(0, tabCount - 1)
                                if (BottomTabs[tappedIdx].route != currentRoute) {
                                    onTap(BottomTabs[tappedIdx].route)
                                }
                                return@awaitEachGesture
                            }

                            // Horizontal drag claimed — start dragging the pill
                            // from its current animated position. Anchor so the
                            // pill follows the finger 1:1 (delta from down).
                            isDragging = true
                            val startPillPx = pillAnim.value
                            val deltaSinceDown = dragChange.position.x - down.position.x
                            dragOffsetPx = (startPillPx + deltaSinceDown)
                                .coerceIn(0f, maxOffsetPx)
                            hoverIndex = ((dragOffsetPx + tabWidthPx / 2f) / tabWidthPx)
                                .toInt().coerceIn(0, tabCount - 1)

                            horizontalDrag(dragChange.id) { change ->
                                dragOffsetPx = (dragOffsetPx + change.positionChange().x)
                                    .coerceIn(0f, maxOffsetPx)
                                val newHover = ((dragOffsetPx + tabWidthPx / 2f) / tabWidthPx)
                                    .toInt().coerceIn(0, tabCount - 1)
                                if (newHover != hoverIndex) {
                                    hoverIndex = newHover
                                    haptic.performHapticFeedback(HapticFeedbackType.TextHandleMove)
                                }
                                change.consume()
                            }

                            // Released — snap pillAnim to the live drag value
                            // so the spring can resume from there, then settle
                            // to the chosen tab and fire the route change.
                            val landed = hoverIndex
                            scope.launch {
                                pillAnim.snapTo(dragOffsetPx)
                                isDragging = false
                                pillAnim.animateTo(
                                    landed * tabWidthPx,
                                    spring(
                                        dampingRatio = Spring.DampingRatioLowBouncy,
                                        stiffness = 320f
                                    )
                                )
                            }
                            if (BottomTabs[landed].route != currentRoute) {
                                onTap(BottomTabs[landed].route)
                            }
                        }
                    }
            )
        }
    }
}

/**
 * Bright "glass-on-glass" pill highlighting the active tab. Layered on top of
 * the bar so it reads like a brighter slab of glass within the larger one.
 */
@Composable
private fun ActivePill(tabWidth: Dp, isDark: Boolean, modifier: Modifier = Modifier) {
    val pillShape = RoundedCornerShape(PillCorner)

    val fill = if (isDark) Color.White.copy(alpha = 0.16f)
               else AppColors.Calorie.copy(alpha = 0.14f)

    val sheen = Brush.verticalGradient(
        colors = if (isDark)
            listOf(Color.White.copy(alpha = 0.20f), Color.White.copy(alpha = 0.0f))
        else
            listOf(Color.White.copy(alpha = 0.55f), Color.White.copy(alpha = 0.10f))
    )

    val border = Brush.linearGradient(
        listOf(
            Color.White.copy(alpha = if (isDark) 0.32f else 0.75f),
            Color.White.copy(alpha = if (isDark) 0.06f else 0.18f)
        )
    )

    Box(
        modifier
            .width(tabWidth)
            .fillMaxHeight()
            .padding(horizontal = PillInsetH, vertical = PillInsetV)
            .clip(pillShape)
            .background(fill)
            .background(sheen)
            .border(0.7.dp, border, pillShape)
    )
}

@Composable
private fun TabItem(
    tab: BottomTab,
    selected: Boolean,
    isDark: Boolean,
    modifier: Modifier = Modifier
) {
    val activeColor = AppColors.Calorie
    val inactiveColor = if (isDark) Color.White.copy(alpha = 0.62f)
                        else Color.Black.copy(alpha = 0.55f)
    val tint = if (selected) activeColor else inactiveColor

    val iconScale by animateFloatAsState(
        targetValue = if (selected) 1.08f else 1.0f,
        animationSpec = spring(
            dampingRatio = Spring.DampingRatioMediumBouncy,
            stiffness = 380f
        ),
        label = "tabIconScale"
    )

    Column(
        modifier = modifier,
        horizontalAlignment = Alignment.CenterHorizontally,
        verticalArrangement = Arrangement.Center
    ) {
        Icon(
            tab.icon,
            contentDescription = tab.label,
            tint = tint,
            modifier = Modifier.size(if (selected) 26.dp else 24.dp).scale(iconScale)
        )
        Spacer(Modifier.height(3.dp))
        Text(
            tab.label,
            color = tint,
            fontSize = 11.sp,
            fontWeight = if (selected) FontWeight.SemiBold else FontWeight.Medium
        )
    }
}
