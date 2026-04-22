package com.apoorvdarshan.calorietracker.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Bolt
import androidx.compose.material.icons.filled.Favorite
import androidx.compose.material.icons.filled.LocalFireDepartment
import androidx.compose.material.icons.filled.Spa
import androidx.compose.material.icons.filled.WaterDrop
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.apoorvdarshan.calorietracker.models.FoodEntry
import com.apoorvdarshan.calorietracker.models.UserProfile
import com.apoorvdarshan.calorietracker.ui.theme.AppColors

/**
 * Verbatim port of struct NutritionDetailView in
 * ios/calorietracker/ContentView.swift (line ~720).
 *
 * Two sections:
 *   Macros: Calories / Protein / Carbs / Fat — each row shows icon +
 *     label + value + unit + '/ goal'.
 *   Detailed Nutrition: Sugar / Added Sugar / Fiber / Saturated Fat /
 *     Mono Unsat. Fat / Poly Unsat. Fat / Cholesterol / Sodium /
 *     Potassium — same icon+label+value+unit pattern, no goal column.
 *
 * Computes the per-day sum from the entries list passed in.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun NutritionDetailSheet(
    entries: List<FoodEntry>,
    profile: UserProfile?,
    onDismiss: () -> Unit
) {
    val state = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val calories = entries.sumOf { it.calories }
    val protein = entries.sumOf { it.protein }
    val carbs = entries.sumOf { it.carbs }
    val fat = entries.sumOf { it.fat }
    val sugar = entries.sumOf { it.sugar ?: 0.0 }
    val addedSugar = entries.sumOf { it.addedSugar ?: 0.0 }
    val fiber = entries.sumOf { it.fiber ?: 0.0 }
    val satFat = entries.sumOf { it.saturatedFat ?: 0.0 }
    val monoFat = entries.sumOf { it.monounsaturatedFat ?: 0.0 }
    val polyFat = entries.sumOf { it.polyunsaturatedFat ?: 0.0 }
    val cholesterol = entries.sumOf { it.cholesterol ?: 0.0 }
    val sodium = entries.sumOf { it.sodium ?: 0.0 }
    val potassium = entries.sumOf { it.potassium ?: 0.0 }

    fun fmt(v: Double): String = if (v == 0.0) "—" else String.format("%.1f", v)

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = state,
        shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp),
        containerColor = MaterialTheme.colorScheme.surface
    ) {
        LazyColumn(
            modifier = Modifier.fillMaxWidth().padding(horizontal = 20.dp).padding(bottom = 16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            item {
                Row(Modifier.fillMaxWidth(), verticalAlignment = Alignment.CenterVertically) {
                    Text("Nutrition Details", fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
                    Spacer(Modifier.weight(1f))
                    TextButton(onClick = onDismiss) { Text("Done", color = AppColors.Calorie) }
                }
            }

            item { SectionHeader("Macros") }
            item {
                Card {
                    DetailRow(Icons.Filled.LocalFireDepartment, "Calories", "$calories", "kcal", goal = "${profile?.effectiveCalories ?: 2000}")
                    Hairline()
                    DetailRow(null, "Protein", "$protein", "g", goal = "${profile?.effectiveProtein ?: 150}", labelGlyph = "P")
                    Hairline()
                    DetailRow(null, "Carbs", "$carbs", "g", goal = "${profile?.effectiveCarbs ?: 220}", labelGlyph = "C")
                    Hairline()
                    DetailRow(null, "Fat", "$fat", "g", goal = "${profile?.effectiveFat ?: 70}", labelGlyph = "F")
                }
            }

            item { SectionHeader("Detailed Nutrition") }
            item {
                Card {
                    DetailRow(null, "Sugar", fmt(sugar), "g", labelGlyph = "S")
                    Hairline()
                    DetailRow(null, "Added Sugar", fmt(addedSugar), "g", labelGlyph = "+")
                    Hairline()
                    DetailRow(Icons.Filled.Spa, "Fiber", fmt(fiber), "g")
                    Hairline()
                    DetailRow(Icons.Filled.WaterDrop, "Saturated Fat", fmt(satFat), "g")
                    Hairline()
                    DetailRow(Icons.Filled.WaterDrop, "Mono Unsat. Fat", fmt(monoFat), "g")
                    Hairline()
                    DetailRow(Icons.Filled.WaterDrop, "Poly Unsat. Fat", fmt(polyFat), "g")
                    Hairline()
                    DetailRow(Icons.Filled.Favorite, "Cholesterol", fmt(cholesterol), "mg")
                    Hairline()
                    DetailRow(Icons.Filled.Bolt, "Sodium", fmt(sodium), "mg")
                    Hairline()
                    DetailRow(Icons.Filled.Bolt, "Potassium", fmt(potassium), "mg")
                }
            }
        }
    }
}

@Composable
private fun Card(content: @Composable () -> Unit) {
    Column(
        Modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(12.dp))
            .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
    ) { content() }
}

@Composable
private fun SectionHeader(title: String) {
    Text(
        title.uppercase(),
        fontSize = 12.sp,
        fontWeight = FontWeight.SemiBold,
        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f),
        letterSpacing = 0.6.sp,
        modifier = Modifier.padding(start = 14.dp, top = 6.dp, bottom = 4.dp)
    )
}

/**
 * Row layout: icon (24dp pink, optional) + label (17sp) + value (17sp pink semibold)
 * + unit (13sp secondary) + optional '/ goal' (12sp tertiary).
 *
 * iOS uses LinearGradient on the SF Symbol; Compose uses a flat tint
 * since Material icons aren't text-paintable.
 */
@Composable
private fun DetailRow(
    icon: ImageVector?,
    label: String,
    value: String,
    unit: String,
    goal: String? = null,
    labelGlyph: String? = null
) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 14.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically,
        horizontalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        if (icon != null) {
            Icon(icon, null, tint = AppColors.Calorie, modifier = Modifier.size(20.dp))
        } else if (labelGlyph != null) {
            Box(
                Modifier
                    .size(20.dp)
                    .clip(RoundedCornerShape(10.dp))
                    .background(AppColors.Calorie),
                contentAlignment = Alignment.Center
            ) {
                Text(labelGlyph, fontSize = 11.sp, fontWeight = FontWeight.Bold, color = androidx.compose.ui.graphics.Color.White)
            }
        } else {
            Spacer(Modifier.width(20.dp))
        }
        Text(label, fontSize = 17.sp, modifier = Modifier.weight(1f))
        Row(verticalAlignment = Alignment.Bottom, horizontalArrangement = Arrangement.spacedBy(3.dp)) {
            Text(value, fontSize = 17.sp, fontWeight = FontWeight.SemiBold, color = AppColors.Calorie)
            Text(unit, fontSize = 13.sp, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f))
        }
        goal?.let {
            Text(
                "/ $it",
                fontSize = 12.sp,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f),
                modifier = Modifier.padding(start = 6.dp)
            )
        }
    }
}

@Composable
private fun Hairline() {
    Box(
        Modifier
            .padding(start = 14.dp)
            .fillMaxWidth()
            .height(0.5.dp)
            .background(MaterialTheme.colorScheme.onSurface.copy(alpha = 0.1f))
    )
}
