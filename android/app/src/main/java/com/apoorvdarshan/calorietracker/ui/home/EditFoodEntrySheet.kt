package com.apoorvdarshan.calorietracker.ui.home

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.asImageBitmap
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import com.apoorvdarshan.calorietracker.models.FoodEntry
import com.apoorvdarshan.calorietracker.models.MealType
import com.apoorvdarshan.calorietracker.ui.theme.AppColors
import kotlin.math.roundToInt

/**
 * Verbatim port of struct EditFoodEntryView in
 * ios/calorietracker/Views/EditFoodEntryView.swift.
 *
 * Same shape as FoodResultSheet but bound to an existing FoodEntry.
 * Sections from iOS:
 *   1. Image / emoji hero (we use emoji-only for now until imageBytes are wired)
 *   2. Food Details — Name TextField (right-aligned)
 *   3. Serving — Quantity TextField + 'g' suffix
 *   4. Nutrition — Calories / Protein / Carbs / Fat (live-scaled)
 *   5. More Nutrition (collapsible) — every present micronutrient
 *   6. Meal Type — segmented picker
 *
 * Save calls onSave(updatedEntry) which the caller pipes to
 * FoodRepository.updateEntry to mutate in place by id.
 */
@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun EditFoodEntrySheet(
    entry: FoodEntry,
    onSave: (FoodEntry) -> Unit,
    onDelete: () -> Unit,
    onDismiss: () -> Unit
) {
    val state = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val baseServing = entry.servingSizeGrams ?: 100.0
    var name by remember { mutableStateOf(entry.name) }
    var servingText by remember { mutableStateOf(formatGrams(baseServing)) }
    val servingGrams = servingText.toDoubleOrNull()?.takeIf { it > 0 } ?: baseServing
    val scale = if (baseServing > 0) servingGrams / baseServing else 1.0
    var mealType by remember { mutableStateOf(entry.mealType) }
    var showMore by remember { mutableStateOf(false) }
    var confirmDelete by remember { mutableStateOf(false) }

    fun s(v: Int) = (v * scale).roundToInt()
    fun s(v: Double?) = v?.let { ((it * scale) * 10).roundToInt() / 10.0 }

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
                Row(
                    Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.SpaceBetween,
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Edit Food", fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
                    Spacer(Modifier.weight(1f))
                    Text(
                        "Cancel",
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
                        modifier = Modifier.clickable(onClick = onDismiss).padding(8.dp)
                    )
                }
            }

            // Image hero (when entry has a saved photo) OR 80sp emoji fallback —
            // matches iOS EditFoodEntryView header section exactly.
            item {
                val ctx = LocalContext.current
                val container = (ctx.applicationContext as com.apoorvdarshan.calorietracker.FudAIApp).container
                val bitmap = remember(entry.imageFilename) {
                    entry.imageFilename?.let { container.imageStore.load(it) }
                }
                Box(Modifier.fillMaxWidth().padding(vertical = 12.dp), contentAlignment = Alignment.Center) {
                    if (bitmap != null) {
                        androidx.compose.foundation.Image(
                            bitmap = bitmap.asImageBitmap(),
                            contentDescription = null,
                            contentScale = androidx.compose.ui.layout.ContentScale.Fit,
                            modifier = Modifier
                                .heightIn(max = 200.dp)
                                .clip(RoundedCornerShape(12.dp))
                        )
                    } else {
                        Text(entry.emoji ?: "🍽", fontSize = 80.sp)
                    }
                }
            }

            // Food Details
            item { SectionHeader("Food Details") }
            item {
                Row(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp))
                        .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
                        .padding(horizontal = 14.dp, vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Name", fontSize = 17.sp, modifier = Modifier.padding(end = 8.dp))
                    Spacer(Modifier.weight(1f))
                    OutlinedTextField(
                        value = name,
                        onValueChange = { name = it },
                        singleLine = true,
                        modifier = Modifier.weight(2f)
                    )
                }
            }

            // Serving
            item { SectionHeader("Serving") }
            item {
                Row(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp))
                        .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
                        .padding(horizontal = 14.dp, vertical = 10.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text("Quantity", fontSize = 17.sp, modifier = Modifier.padding(end = 8.dp))
                    Spacer(Modifier.weight(1f))
                    OutlinedTextField(
                        value = servingText,
                        onValueChange = { servingText = it },
                        singleLine = true,
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                        modifier = Modifier.width(96.dp)
                    )
                    Spacer(Modifier.width(6.dp))
                    Text("g", fontSize = 17.sp, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f))
                }
            }

            // Meal Type
            item { SectionHeader("Meal") }
            item {
                Row(
                    Modifier
                        .fillMaxWidth()
                        .clip(RoundedCornerShape(12.dp))
                        .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
                        .padding(horizontal = 8.dp, vertical = 6.dp)
                ) {
                    for (m in MealType.values()) {
                        val isSel = m == mealType
                        Box(
                            Modifier
                                .weight(1f)
                                .clip(RoundedCornerShape(8.dp))
                                .background(if (isSel) AppColors.Calorie else Color.Transparent)
                                .clickable { mealType = m }
                                .padding(vertical = 8.dp),
                            contentAlignment = Alignment.Center
                        ) {
                            Text(
                                m.displayName,
                                fontSize = 13.sp,
                                fontWeight = FontWeight.Medium,
                                color = if (isSel) Color.White else MaterialTheme.colorScheme.onSurface
                            )
                        }
                    }
                }
            }

            // Nutrition
            item { SectionHeader("Nutrition") }
            item {
                Column(
                    Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp))
                        .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
                ) {
                    NutritionRow("Calories", "${s(entry.calories)} kcal", isHero = true)
                    Hairline()
                    NutritionRow("Protein", "${s(entry.protein)} g")
                    Hairline()
                    NutritionRow("Carbs", "${s(entry.carbs)} g")
                    Hairline()
                    NutritionRow("Fat", "${s(entry.fat)} g")
                }
            }

            // More Nutrition (collapsible)
            val micros = listOf(
                "Sugar" to s(entry.sugar)?.let { "$it g" },
                "Added Sugar" to s(entry.addedSugar)?.let { "$it g" },
                "Fiber" to s(entry.fiber)?.let { "$it g" },
                "Saturated Fat" to s(entry.saturatedFat)?.let { "$it g" },
                "Mono Fat" to s(entry.monounsaturatedFat)?.let { "$it g" },
                "Poly Fat" to s(entry.polyunsaturatedFat)?.let { "$it g" },
                "Cholesterol" to s(entry.cholesterol)?.let { "$it mg" },
                "Sodium" to s(entry.sodium)?.let { "$it mg" },
                "Potassium" to s(entry.potassium)?.let { "$it mg" }
            )
            if (micros.any { it.second != null }) {
                item {
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .padding(start = 14.dp, top = 6.dp)
                            .clickable { showMore = !showMore },
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text(
                            (if (showMore) "▾  " else "▸  ") + "More Nutrition",
                            fontSize = 14.sp,
                            color = AppColors.Calorie,
                            fontWeight = FontWeight.Medium
                        )
                    }
                }
                if (showMore) {
                    item {
                        Column(
                            Modifier.fillMaxWidth().clip(RoundedCornerShape(12.dp))
                                .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
                        ) {
                            val present = micros.filter { it.second != null }
                            present.forEachIndexed { idx, (label, value) ->
                                if (idx > 0) Hairline()
                                NutritionRow(label, value!!, dim = true)
                            }
                        }
                    }
                }
            }

            // Save / Delete
            item {
                Spacer(Modifier.height(8.dp))
                Button(
                    onClick = {
                        val updated = entry.copy(
                            name = name.trim().ifEmpty { entry.name },
                            calories = s(entry.calories),
                            protein = s(entry.protein),
                            carbs = s(entry.carbs),
                            fat = s(entry.fat),
                            mealType = mealType,
                            sugar = s(entry.sugar),
                            addedSugar = s(entry.addedSugar),
                            fiber = s(entry.fiber),
                            saturatedFat = s(entry.saturatedFat),
                            monounsaturatedFat = s(entry.monounsaturatedFat),
                            polyunsaturatedFat = s(entry.polyunsaturatedFat),
                            cholesterol = s(entry.cholesterol),
                            sodium = s(entry.sodium),
                            potassium = s(entry.potassium),
                            servingSizeGrams = servingGrams
                        )
                        onSave(updated)
                    },
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.Calorie),
                    shape = RoundedCornerShape(14.dp),
                    modifier = Modifier.fillMaxWidth().height(52.dp)
                ) {
                    Text("Save", color = Color.White, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
                }
                Spacer(Modifier.height(8.dp))
                OutlinedButton(
                    onClick = { confirmDelete = true },
                    shape = RoundedCornerShape(14.dp),
                    modifier = Modifier.fillMaxWidth().height(52.dp)
                ) {
                    Text("Delete", color = AppColors.Calorie, fontSize = 17.sp, fontWeight = FontWeight.SemiBold)
                }
                TextButton(onClick = onDismiss, modifier = Modifier.fillMaxWidth()) { Text("Cancel") }
            }
        }
    }

    if (confirmDelete) {
        AlertDialog(
            onDismissRequest = { confirmDelete = false },
            title = { Text("Delete this entry?") },
            text = { Text("This removes ${entry.name} from your log.") },
            confirmButton = {
                TextButton(onClick = {
                    confirmDelete = false
                    onDelete()
                }) { Text("Delete", color = AppColors.Calorie, fontWeight = FontWeight.SemiBold) }
            },
            dismissButton = {
                TextButton(onClick = { confirmDelete = false }) { Text("Cancel") }
            }
        )
    }
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

@Composable
private fun NutritionRow(label: String, value: String, isHero: Boolean = false, dim: Boolean = false) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 12.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            label,
            fontSize = if (isHero) 17.sp else 15.sp,
            color = if (dim) MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    else MaterialTheme.colorScheme.onSurface,
            modifier = Modifier.weight(1f)
        )
        Text(
            value,
            fontSize = if (isHero) 22.sp else 15.sp,
            fontWeight = if (isHero) FontWeight.Bold else FontWeight.Medium,
            color = if (isHero) AppColors.Calorie else MaterialTheme.colorScheme.onSurface
        )
    }
}

@Composable
private fun Hairline() {
    Box(
        Modifier
            .padding(start = 16.dp)
            .fillMaxWidth()
            .height(0.5.dp)
            .background(MaterialTheme.colorScheme.onSurface.copy(alpha = 0.1f))
    )
}

private fun formatGrams(value: Double): String =
    if (value == value.toInt().toDouble()) value.toInt().toString()
    else String.format("%.1f", value)
