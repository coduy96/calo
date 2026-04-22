package com.apoorvdarshan.calorietracker.ui.home

import android.net.Uri
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.PickVisualMediaRequest
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxHeight
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Edit
import androidx.compose.material.icons.filled.Bookmark
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Restaurant
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.apoorvdarshan.calorietracker.AppContainer
import com.apoorvdarshan.calorietracker.models.FoodEntry
import com.apoorvdarshan.calorietracker.models.MealType
import com.apoorvdarshan.calorietracker.ui.components.ActivityRing
import com.apoorvdarshan.calorietracker.ui.components.RingCenterLabel
import com.apoorvdarshan.calorietracker.ui.components.WeekStrip
import com.apoorvdarshan.calorietracker.ui.theme.AppColors
import java.time.LocalDate
import java.time.LocalTime
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(container: AppContainer) {
    val vm: HomeViewModel = viewModel(factory = HomeViewModel.Factory(container))
    val ui by vm.ui.collectAsState()
    val ctx = LocalContext.current

    var showText by remember { mutableStateOf(false) }
    var showVoice by remember { mutableStateOf(false) }
    var showSaved by remember { mutableStateOf(false) }

    val picker = rememberLauncherForActivityResult(
        ActivityResultContracts.PickVisualMedia()
    ) { uri: Uri? ->
        if (uri != null) {
            val bytes = ctx.contentResolver.openInputStream(uri)?.use { it.readBytes() }
            if (bytes != null) vm.analyzePhoto(bytes)
        }
    }

    Scaffold(containerColor = MaterialTheme.colorScheme.background) { padding ->
        LazyColumn(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            contentPadding = androidx.compose.foundation.layout.PaddingValues(bottom = 24.dp)
        ) {
            item { Greeting(profileName = ui.profile?.displayName) }
            item { Spacer(Modifier.height(12.dp)) }
            item {
                Box(Modifier.padding(horizontal = 20.dp)) {
                    WeekStrip(selected = LocalDate.now(), onSelect = { /* TODO: date switching */ })
                }
            }
            item { Spacer(Modifier.height(20.dp)) }
            item { MacroHero(ui = ui) }
            item { Spacer(Modifier.height(18.dp)) }
            item {
                Row(
                    Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 20.dp),
                    horizontalArrangement = Arrangement.spacedBy(8.dp)
                ) {
                    QuickPill(
                        icon = Icons.Filled.CameraAlt,
                        label = "Photo",
                        modifier = Modifier.weight(1f)
                    ) {
                        picker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                    }
                    QuickPill(
                        icon = Icons.Filled.Edit,
                        label = "Text",
                        modifier = Modifier.weight(1f)
                    ) { showText = true }
                    QuickPill(
                        icon = Icons.Filled.Mic,
                        label = "Voice",
                        modifier = Modifier.weight(1f)
                    ) { showVoice = true }
                    QuickPill(
                        icon = Icons.Filled.Bookmark,
                        label = "Saved",
                        modifier = Modifier.weight(1f)
                    ) { showSaved = true }
                }
            }
            item { Spacer(Modifier.height(24.dp)) }
            item {
                Row(
                    Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 24.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Text(
                        "Today's log",
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    Spacer(Modifier.weight(1f))
                    Text(
                        "${ui.todayEntries.size} entries",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.55f)
                    )
                }
            }
            item { Spacer(Modifier.height(8.dp)) }

            // Group by meal
            val grouped: Map<MealType, List<FoodEntry>> = ui.todayEntries.groupBy { it.mealType }
            val ordered = listOf(MealType.BREAKFAST, MealType.LUNCH, MealType.DINNER, MealType.SNACK, MealType.OTHER)
            for (meal in ordered) {
                val entries = grouped[meal] ?: emptyList()
                if (entries.isEmpty() && ui.todayEntries.isNotEmpty()) continue
                item { Spacer(Modifier.height(10.dp)) }
                item {
                    MealHeader(meal = meal, count = entries.size, total = entries.sumOf { it.calories })
                }
                if (entries.isEmpty()) {
                    item { EmptyMealCard(meal = meal) }
                } else {
                    items(entries, key = { it.id }) { entry ->
                        FoodRow(entry = entry, onDelete = { vm.deleteEntry(entry.id) })
                    }
                }
            }

            item { Spacer(Modifier.height(24.dp)) }
        }
    }

    if (showText) {
        TextInputDialog(
            onDismiss = { showText = false },
            onSubmit = {
                showText = false
                vm.analyzeText(it)
            }
        )
    }

    if (showVoice) {
        VoiceInputSheet(
            container = container,
            onDismiss = { showVoice = false },
            onSubmit = {
                showVoice = false
                vm.analyzeText(it)
            }
        )
    }

    if (showSaved) {
        SavedMealsSheet(
            container = container,
            onDismiss = { showSaved = false },
            onRelogEntry = { vm.relogMeal(it) }
        )
    }

    if (ui.analyzing) {
        AnalyzingOverlay()
    }

    ui.pendingAnalysis?.let { analysis ->
        AnalysisResultDialog(
            analysis = analysis,
            onSave = { vm.saveAnalysis() },
            onDismiss = { vm.dismissPending() }
        )
    }

    ui.error?.let { err ->
        AlertDialog(
            onDismissRequest = { vm.dismissPending() },
            title = { Text("Something went wrong") },
            text = { Text(err) },
            confirmButton = { TextButton(onClick = { vm.dismissPending() }) { Text("OK") } }
        )
    }
}

@Composable
private fun Greeting(profileName: String?) {
    val hour = LocalTime.now().hour
    val greeting = when (hour) {
        in 5..11 -> "Good morning"
        in 12..16 -> "Good afternoon"
        in 17..21 -> "Good evening"
        else -> "Good night"
    }
    val today = LocalDate.now().format(DateTimeFormatter.ofPattern("EEEE, MMM d"))

    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 16.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Column(Modifier.weight(1f)) {
            Text(
                today.uppercase(),
                style = MaterialTheme.typography.labelSmall,
                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.55f),
                letterSpacing = 1.2.sp
            )
            Spacer(Modifier.height(4.dp))
            Text(
                "$greeting${if (!profileName.isNullOrBlank() && profileName != "User") ", ${profileName.split(' ').first()}" else ""}",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold
            )
        }
        val initial = profileName?.firstOrNull()?.uppercase() ?: "F"
        Box(
            Modifier
                .size(44.dp)
                .clip(CircleShape)
                .background(AppColors.CalorieGradient),
            contentAlignment = Alignment.Center
        ) {
            Text(initial, color = Color.White, fontWeight = FontWeight.Bold)
        }
    }
}

@Composable
private fun MacroHero(ui: HomeUiState) {
    val profile = ui.profile
    val calGoal = profile?.effectiveCalories ?: 2000
    val proteinGoal = profile?.effectiveProtein ?: 150
    val carbsGoal = profile?.effectiveCarbs ?: 220
    val fatGoal = profile?.effectiveFat ?: 70
    val remaining = maxOf(0, calGoal - ui.caloriesToday)

    Card(
        shape = RoundedCornerShape(28.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp)
    ) {
        Row(
            modifier = Modifier.padding(20.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            ActivityRing(
                progress = if (calGoal > 0) ui.caloriesToday.toFloat() / calGoal else 0f,
                size = 140.dp,
                strokeWidth = 14.dp
            ) {
                RingCenterLabel(
                    primary = "$remaining",
                    secondary = "kcal left"
                )
            }
            Spacer(Modifier.width(20.dp))
            Column(Modifier.fillMaxHeight(), verticalArrangement = Arrangement.spacedBy(14.dp)) {
                MacroBar("Protein", ui.proteinToday, proteinGoal)
                MacroBar("Carbs", ui.carbsToday, carbsGoal)
                MacroBar("Fat", ui.fatToday, fatGoal)
            }
        }
    }
}

@Composable
private fun MacroBar(label: String, current: Int, goal: Int) {
    val progress = if (goal > 0) (current.toFloat() / goal).coerceIn(0f, 1f) else 0f
    Column {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Text(
                label,
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.7f),
                fontWeight = FontWeight.Medium
            )
            Spacer(Modifier.weight(1f))
            Text(
                "$current",
                style = MaterialTheme.typography.bodyMedium,
                fontWeight = FontWeight.SemiBold
            )
            Text(
                " / ${goal}g",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.5f)
            )
        }
        Spacer(Modifier.height(4.dp))
        LinearProgressIndicator(
            progress = { progress },
            color = AppColors.Calorie,
            trackColor = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.08f),
            modifier = Modifier
                .fillMaxWidth()
                .height(6.dp)
                .clip(RoundedCornerShape(3.dp))
        )
    }
}

@Composable
private fun QuickPill(
    icon: ImageVector,
    label: String,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    Box(
        modifier = modifier
            .height(52.dp)
            .clip(RoundedCornerShape(18.dp))
            .background(MaterialTheme.colorScheme.surface)
            .clickable(onClick = onClick),
        contentAlignment = Alignment.Center
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Icon(icon, contentDescription = label, tint = AppColors.Calorie, modifier = Modifier.size(20.dp))
            Spacer(Modifier.width(8.dp))
            Text(
                label,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.SemiBold
            )
        }
    }
}

@Composable
private fun MealHeader(meal: MealType, count: Int, total: Int) {
    Row(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 24.dp, vertical = 6.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(
            meal.displayName,
            style = MaterialTheme.typography.titleSmall,
            fontWeight = FontWeight.SemiBold
        )
        Spacer(Modifier.weight(1f))
        if (count > 0) {
            Text(
                "$total kcal",
                style = MaterialTheme.typography.labelMedium,
                color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.55f)
            )
        }
    }
}

@Composable
private fun EmptyMealCard(meal: MealType) {
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface.copy(alpha = 0.4f)),
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 4.dp)
    ) {
        Row(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 18.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                Icons.Filled.Restaurant,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.3f),
                modifier = Modifier.size(20.dp)
            )
            Spacer(Modifier.width(12.dp))
            Text(
                "No ${meal.displayName.lowercase()} logged yet",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f)
            )
        }
    }
}

@Composable
private fun FoodRow(entry: FoodEntry, onDelete: () -> Unit) {
    val zone = ZoneId.systemDefault()
    val timeFmt = DateTimeFormatter.ofPattern("h:mm a", Locale.US).withZone(zone)
    Card(
        shape = RoundedCornerShape(16.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 20.dp, vertical = 4.dp)
    ) {
        Row(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 14.dp, vertical = 12.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                Modifier
                    .size(42.dp)
                    .clip(CircleShape)
                    .background(AppColors.Calorie.copy(alpha = 0.15f)),
                contentAlignment = Alignment.Center
            ) {
                Text(entry.emoji ?: "🍽", fontSize = 20.sp)
            }
            Spacer(Modifier.width(14.dp))
            Column(Modifier.weight(1f)) {
                Text(
                    entry.name,
                    style = MaterialTheme.typography.bodyLarge,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1
                )
                Spacer(Modifier.height(2.dp))
                Text(
                    "${entry.calories} kcal · P ${entry.protein} · C ${entry.carbs} · F ${entry.fat} · ${timeFmt.format(entry.timestamp)}",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f),
                    maxLines = 1
                )
            }
            IconButton(onClick = onDelete) {
                Icon(
                    Icons.Filled.Delete,
                    contentDescription = "Delete",
                    tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f)
                )
            }
        }
    }
}

@Composable
private fun AnalyzingOverlay() {
    Box(
        Modifier
            .fillMaxSize()
            .background(Color(0x99000000)),
        contentAlignment = Alignment.Center
    ) {
        Card(shape = RoundedCornerShape(20.dp)) {
            Column(
                Modifier.padding(32.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                CircularProgressIndicator(color = AppColors.Calorie)
                Spacer(Modifier.height(16.dp))
                Text(
                    "Analyzing…",
                    style = MaterialTheme.typography.bodyMedium,
                    fontWeight = FontWeight.Medium
                )
            }
        }
    }
}

@Composable
private fun AnalysisResultDialog(
    analysis: com.apoorvdarshan.calorietracker.services.ai.FoodAnalysis,
    onSave: () -> Unit,
    onDismiss: () -> Unit
) {
    AlertDialog(
        onDismissRequest = onDismiss,
        shape = RoundedCornerShape(24.dp),
        title = { Text("${analysis.emoji ?: "🍽"}  ${analysis.name}", fontWeight = FontWeight.SemiBold) },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text(
                    "${analysis.calories} kcal",
                    style = MaterialTheme.typography.headlineSmall,
                    fontWeight = FontWeight.Bold
                )
                Text("Protein: ${analysis.protein}g")
                Text("Carbs: ${analysis.carbs}g")
                Text("Fat: ${analysis.fat}g")
                if (analysis.fiber != null || analysis.sugar != null || analysis.sodium != null) {
                    Spacer(Modifier.height(6.dp))
                    analysis.fiber?.let { Text("Fiber: ${it}g", style = MaterialTheme.typography.bodySmall) }
                    analysis.sugar?.let { Text("Sugar: ${it}g", style = MaterialTheme.typography.bodySmall) }
                    analysis.saturatedFat?.let { Text("Sat fat: ${it}g", style = MaterialTheme.typography.bodySmall) }
                    analysis.sodium?.let { Text("Sodium: ${it}mg", style = MaterialTheme.typography.bodySmall) }
                    analysis.potassium?.let { Text("Potassium: ${it}mg", style = MaterialTheme.typography.bodySmall) }
                    analysis.cholesterol?.let { Text("Cholesterol: ${it}mg", style = MaterialTheme.typography.bodySmall) }
                }
                analysis.servingSizeGrams.let {
                    Text(
                        "Serving: ~${it.toInt()}g",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f)
                    )
                }
            }
        },
        confirmButton = { Button(onClick = onSave) { Text("Save") } },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Discard") } }
    )
}

@Composable
private fun TextInputDialog(onDismiss: () -> Unit, onSubmit: (String) -> Unit) {
    var input by remember { mutableStateOf("") }
    AlertDialog(
        onDismissRequest = onDismiss,
        shape = RoundedCornerShape(24.dp),
        title = { Text("Describe your meal") },
        text = {
            OutlinedTextField(
                value = input,
                onValueChange = { input = it },
                placeholder = { Text("e.g. 2 eggs, toast, small OJ") },
                modifier = Modifier.fillMaxWidth()
            )
        },
        confirmButton = {
            Button(onClick = { if (input.isNotBlank()) onSubmit(input) }) { Text("Analyze") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } }
    )
}
