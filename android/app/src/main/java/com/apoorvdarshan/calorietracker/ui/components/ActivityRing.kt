package com.apoorvdarshan.calorietracker.ui.components

import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.Canvas
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.size
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.geometry.Offset
import androidx.compose.ui.geometry.Size
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.StrokeCap
import androidx.compose.ui.graphics.drawscope.Stroke
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import com.apoorvdarshan.calorietracker.ui.theme.AppColors

/**
 * iOS Activity-ring-style circular progress indicator. Thick stroke, pink
 * gradient fill, starts at 12-o'clock and sweeps clockwise.
 */
@Composable
fun ActivityRing(
    progress: Float,
    modifier: Modifier = Modifier,
    size: Dp = 160.dp,
    strokeWidth: Dp = 14.dp,
    trackColor: Color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f),
    centerContent: @Composable () -> Unit = {}
) {
    val animated by animateFloatAsState(
        targetValue = progress.coerceIn(0f, 1.5f),
        animationSpec = tween(durationMillis = 600),
        label = "ringProgress"
    )

    Box(modifier = modifier.size(size), contentAlignment = Alignment.Center) {
        Canvas(modifier = Modifier.size(size)) {
            val stroke = Stroke(width = strokeWidth.toPx(), cap = StrokeCap.Round)
            val diameter = this.size.minDimension - strokeWidth.toPx()
            val topLeft = Offset(
                x = (this.size.width - diameter) / 2f,
                y = (this.size.height - diameter) / 2f
            )
            val arcSize = Size(diameter, diameter)

            // Track
            drawArc(
                color = trackColor,
                startAngle = -90f,
                sweepAngle = 360f,
                useCenter = false,
                topLeft = topLeft,
                size = arcSize,
                style = stroke
            )

            // Progress sweep with pink gradient
            if (animated > 0f) {
                drawArc(
                    brush = Brush.sweepGradient(
                        colors = listOf(AppColors.CalorieStart, AppColors.CalorieEnd, AppColors.CalorieStart),
                        center = Offset(this.size.width / 2f, this.size.height / 2f)
                    ),
                    startAngle = -90f,
                    sweepAngle = 360f * animated.coerceAtMost(1f),
                    useCenter = false,
                    topLeft = topLeft,
                    size = arcSize,
                    style = stroke
                )
            }
        }
        centerContent()
    }
}

/** Ready-made center label: big number + small label (e.g. "1,247\nkcal"). */
@Composable
fun RingCenterLabel(primary: String, secondary: String) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            primary,
            style = MaterialTheme.typography.headlineLarge,
            fontWeight = FontWeight.Bold
        )
        Text(
            secondary,
            style = MaterialTheme.typography.labelSmall,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
        )
    }
}
