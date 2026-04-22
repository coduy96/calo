package com.apoorvdarshan.calorietracker.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.apoorvdarshan.calorietracker.ui.theme.AppColors
import java.time.DayOfWeek
import java.time.LocalDate
import java.time.temporal.WeekFields
import java.util.Locale

/**
 * iOS-style horizontal day-of-week strip. Shows 7 days centered around `today`
 * (or the current selection's week). Selected day gets the pink gradient pill.
 */
@Composable
fun WeekStrip(
    selected: LocalDate,
    onSelect: (LocalDate) -> Unit,
    modifier: Modifier = Modifier
) {
    // Start week on the user's locale's first day.
    val firstDow = remember { WeekFields.of(Locale.getDefault()).firstDayOfWeek }
    val weekStart = remember(selected, firstDow) {
        val offset = ((selected.dayOfWeek.value - firstDow.value) + 7) % 7
        selected.minusDays(offset.toLong())
    }
    val today = remember { LocalDate.now() }

    Row(
        modifier = modifier.fillMaxWidth(),
        horizontalArrangement = Arrangement.SpaceEvenly
    ) {
        for (i in 0..6) {
            val date = weekStart.plusDays(i.toLong())
            val isSelected = date == selected
            val isToday = date == today

            val labelColor =
                if (isSelected) Color.White
                else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f)

            val numberColor =
                if (isSelected) Color.White
                else MaterialTheme.colorScheme.onSurface

            Column(
                horizontalAlignment = Alignment.CenterHorizontally,
                modifier = Modifier
                    .weight(1f)
                    .padding(horizontal = 2.dp)
                    .clip(RoundedCornerShape(18.dp))
                    .clickable { onSelect(date) }
                    .background(
                        if (isSelected) AppColors.CalorieGradient
                        else Brush.linearGradient(listOf(Color.Transparent, Color.Transparent))
                    )
                    .padding(vertical = 10.dp)
            ) {
                Text(
                    shortDayName(date.dayOfWeek),
                    style = MaterialTheme.typography.labelSmall,
                    color = labelColor
                )
                Spacer(Modifier.height(4.dp))
                Text(
                    date.dayOfMonth.toString(),
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = if (isSelected || isToday) FontWeight.Bold else FontWeight.SemiBold,
                    color = numberColor
                )
                Spacer(Modifier.height(4.dp))
                Box(
                    Modifier
                        .size(5.dp)
                        .clip(CircleShape)
                        .background(
                            when {
                                isSelected -> Color.White
                                isToday -> AppColors.Calorie
                                else -> Color.Transparent
                            }
                        )
                )
            }
        }
    }
}

private fun shortDayName(dow: DayOfWeek): String = when (dow) {
    DayOfWeek.MONDAY -> "M"
    DayOfWeek.TUESDAY -> "T"
    DayOfWeek.WEDNESDAY -> "W"
    DayOfWeek.THURSDAY -> "T"
    DayOfWeek.FRIDAY -> "F"
    DayOfWeek.SATURDAY -> "S"
    DayOfWeek.SUNDAY -> "S"
}
