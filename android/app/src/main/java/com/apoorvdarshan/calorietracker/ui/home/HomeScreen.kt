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
import androidx.compose.material.icons.filled.Mic
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
import androidx.compose.material3.TopAppBar
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.apoorvdarshan.calorietracker.AppContainer
import com.apoorvdarshan.calorietracker.models.FoodEntry
import com.apoorvdarshan.calorietracker.ui.theme.AppColors
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

    val picker = rememberLauncherForActivityResult(
        ActivityResultContracts.PickVisualMedia()
    ) { uri: Uri? ->
        if (uri != null) {
            val bytes = ctx.contentResolver.openInputStream(uri)?.use { it.readBytes() }
            if (bytes != null) vm.analyzePhoto(bytes)
        }
    }

    Scaffold(topBar = { TopAppBar(title = { Text("Home") }) }) { padding ->
        Column(
            Modifier
                .fillMaxSize()
                .padding(padding)
                .padding(horizontal = 16.dp)
        ) {
            MacroHeader(ui = ui)

            Spacer(Modifier.height(16.dp))

            Row(horizontalArrangement = Arrangement.spacedBy(12.dp)) {
                QuickButton(label = "Photo", icon = Icons.Filled.CameraAlt) {
                    picker.launch(PickVisualMediaRequest(ActivityResultContracts.PickVisualMedia.ImageOnly))
                }
                QuickButton(label = "Text", icon = Icons.Filled.Edit) { showText = true }
                QuickButton(label = "Voice", icon = Icons.Filled.Mic) {
                    // Voice flow lands in a follow-up commit. For now this is a stub.
                }
            }

            Spacer(Modifier.height(16.dp))

            Text("Today's log", style = MaterialTheme.typography.titleMedium)

            LazyColumn(
                Modifier
                    .fillMaxSize()
                    .padding(top = 8.dp),
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(ui.todayEntries, key = { it.id }) { entry ->
                    FoodRow(entry = entry, onDelete = { vm.deleteEntry(entry.id) })
                }
            }
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
private fun MacroHeader(ui: HomeUiState) {
    val profile = ui.profile
    val calGoal = profile?.effectiveCalories ?: 2000
    val proteinGoal = profile?.effectiveProtein ?: 150
    val carbsGoal = profile?.effectiveCarbs ?: 220
    val fatGoal = profile?.effectiveFat ?: 70

    Card(
        shape = RoundedCornerShape(20.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        modifier = Modifier
            .fillMaxWidth()
            .padding(top = 8.dp)
    ) {
        Column(Modifier.padding(16.dp)) {
            Text("Today", style = MaterialTheme.typography.labelSmall, color = Color(0xFF8E8E93))
            Text(
                "${ui.caloriesToday} / $calGoal kcal",
                style = MaterialTheme.typography.headlineMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(Modifier.height(10.dp))
            LinearProgressIndicator(
                progress = { (ui.caloriesToday.toFloat() / calGoal.toFloat()).coerceIn(0f, 1f) },
                color = AppColors.Calorie,
                modifier = Modifier
                    .fillMaxWidth()
                    .height(8.dp)
                    .clip(RoundedCornerShape(4.dp))
            )
            Spacer(Modifier.height(12.dp))
            Row(horizontalArrangement = Arrangement.SpaceBetween, modifier = Modifier.fillMaxWidth()) {
                MacroStat("Protein", ui.proteinToday, proteinGoal)
                MacroStat("Carbs", ui.carbsToday, carbsGoal)
                MacroStat("Fat", ui.fatToday, fatGoal)
            }
        }
    }
}

@Composable
private fun MacroStat(label: String, current: Int, goal: Int) {
    Column(horizontalAlignment = Alignment.CenterHorizontally) {
        Text(
            "$current",
            style = MaterialTheme.typography.titleLarge,
            fontWeight = FontWeight.SemiBold
        )
        Text("/ ${goal}g", style = MaterialTheme.typography.bodySmall, color = Color(0xFF8E8E93))
        Text(label, style = MaterialTheme.typography.labelMedium)
    }
}

@Composable
private fun QuickButton(label: String, icon: androidx.compose.ui.graphics.vector.ImageVector, onClick: () -> Unit) {
    Card(
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(containerColor = AppColors.Calorie),
        modifier = Modifier
            .size(width = 108.dp, height = 68.dp)
            .clickable(onClick = onClick)
    ) {
        Column(
            Modifier.fillMaxSize(),
            verticalArrangement = Arrangement.Center,
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(icon, contentDescription = label, tint = Color.White)
            Spacer(Modifier.height(4.dp))
            Text(label, color = Color.White, style = MaterialTheme.typography.labelMedium)
        }
    }
}

@Composable
private fun FoodRow(entry: FoodEntry, onDelete: () -> Unit) {
    val zone = ZoneId.systemDefault()
    val timeFmt = DateTimeFormatter.ofPattern("h:mm a", Locale.US).withZone(zone)
    Card(
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Row(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 14.dp, vertical = 10.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                Modifier
                    .size(36.dp)
                    .clip(CircleShape)
                    .background(AppColors.Calorie.copy(alpha = 0.15f)),
                contentAlignment = Alignment.Center
            ) {
                Text(entry.emoji ?: "🍽️")
            }
            Spacer(Modifier.width(12.dp))
            Column(Modifier.weight(1f)) {
                Text(entry.name, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.SemiBold)
                Text(
                    "${entry.calories} kcal · ${entry.protein}P / ${entry.carbs}C / ${entry.fat}F · ${timeFmt.format(entry.timestamp)}",
                    style = MaterialTheme.typography.bodySmall,
                    color = Color(0xFF8E8E93)
                )
            }
            IconButton(onClick = onDelete) {
                Icon(Icons.Filled.Delete, contentDescription = "Delete")
            }
        }
    }
}

@Composable
private fun AnalyzingOverlay() {
    Box(
        Modifier
            .fillMaxSize()
            .background(Color(0x88000000)),
        contentAlignment = Alignment.Center
    ) {
        Card(shape = RoundedCornerShape(16.dp)) {
            Column(
                Modifier.padding(32.dp),
                horizontalAlignment = Alignment.CenterHorizontally
            ) {
                CircularProgressIndicator(color = AppColors.Calorie)
                Spacer(Modifier.height(16.dp))
                Text("Analyzing...", style = MaterialTheme.typography.bodyMedium)
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
        title = { Text("${analysis.emoji ?: "🍽️"}  ${analysis.name}") },
        text = {
            Column(verticalArrangement = Arrangement.spacedBy(6.dp)) {
                Text("${analysis.calories} kcal")
                Text("Protein: ${analysis.protein}g")
                Text("Carbs: ${analysis.carbs}g")
                Text("Fat: ${analysis.fat}g")
                if (analysis.fiber != null || analysis.sugar != null || analysis.sodium != null) {
                    Spacer(Modifier.height(4.dp))
                    analysis.fiber?.let { Text("Fiber: ${it}g", style = MaterialTheme.typography.bodySmall) }
                    analysis.sugar?.let { Text("Sugar: ${it}g", style = MaterialTheme.typography.bodySmall) }
                    analysis.saturatedFat?.let { Text("Sat fat: ${it}g", style = MaterialTheme.typography.bodySmall) }
                    analysis.sodium?.let { Text("Sodium: ${it}mg", style = MaterialTheme.typography.bodySmall) }
                    analysis.potassium?.let { Text("Potassium: ${it}mg", style = MaterialTheme.typography.bodySmall) }
                    analysis.cholesterol?.let { Text("Cholesterol: ${it}mg", style = MaterialTheme.typography.bodySmall) }
                }
                analysis.servingSizeGrams.let { Text("Serving: ~${it.toInt()}g", style = MaterialTheme.typography.bodySmall, color = Color(0xFF8E8E93)) }
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
        title = { Text("Describe your meal") },
        text = {
            OutlinedTextField(
                value = input,
                onValueChange = { input = it },
                placeholder = { Text("e.g. 2 eggs, toast, small orange juice") },
                modifier = Modifier.fillMaxWidth()
            )
        },
        confirmButton = {
            Button(onClick = { if (input.isNotBlank()) onSubmit(input) }) { Text("Analyze") }
        },
        dismissButton = { TextButton(onClick = onDismiss) { Text("Cancel") } }
    )
}
