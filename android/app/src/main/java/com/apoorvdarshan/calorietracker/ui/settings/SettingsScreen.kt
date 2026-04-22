package com.apoorvdarshan.calorietracker.ui.settings

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
import androidx.compose.foundation.layout.heightIn
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyListScope
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.rememberModalBottomSheetState
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import com.apoorvdarshan.calorietracker.AppContainer
import com.apoorvdarshan.calorietracker.models.ActivityLevel
import com.apoorvdarshan.calorietracker.models.AIProvider
import com.apoorvdarshan.calorietracker.models.AutoBalanceMacro
import com.apoorvdarshan.calorietracker.models.Gender
import com.apoorvdarshan.calorietracker.models.SpeechProvider
import com.apoorvdarshan.calorietracker.models.WeightGoal
import com.apoorvdarshan.calorietracker.ui.components.DecimalWheelPicker
import com.apoorvdarshan.calorietracker.ui.components.FeetInchesWheelPicker
import com.apoorvdarshan.calorietracker.ui.components.NumericWheelPicker
import com.apoorvdarshan.calorietracker.ui.components.SplitDecimalWheelPicker
import com.apoorvdarshan.calorietracker.ui.components.UnitToggle
import com.apoorvdarshan.calorietracker.ui.theme.AppColors
import com.apoorvdarshan.calorietracker.ui.theme.IOSColors
import com.apoorvdarshan.calorietracker.ui.theme.IOSFont
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import java.util.Locale

private enum class SettingsSheet {
    AI_PROVIDER, AI_MODEL, API_KEY, CUSTOM_BASE_URL, SPEECH_PROVIDER, SPEECH_KEY,
    GENDER, HEIGHT, WEIGHT, BODY_FAT, ACTIVITY, GOAL, GOAL_WEIGHT, GOAL_SPEED, MACROS
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(container: AppContainer, nav: NavHostController) {
    val vm: SettingsViewModel = viewModel(factory = SettingsViewModel.Factory(container))
    val ui by vm.ui.collectAsState()
    val profile = ui.profile

    var sheet by remember { mutableStateOf<SettingsSheet?>(null) }
    var showDeleteDialog by remember { mutableStateOf(false) }
    var showClearFoodDialog by remember { mutableStateOf(false) }
    var showRecalcDialog by remember { mutableStateOf(false) }

    Scaffold(topBar = { TopAppBar(title = { Text("Settings") }) }) { padding ->
        Column(
            Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            SectionCard(title = "You") {
                profile?.let { p ->
                    SettingRow("Gender", p.gender.displayName) { sheet = SettingsSheet.GENDER }
                    HorizontalDivider()
                    SettingRow(
                        "Height",
                        if (ui.useMetric) "${p.heightCm.toInt()} cm"
                        else feetInchesLabel(p.heightCm.toInt())
                    ) { sheet = SettingsSheet.HEIGHT }
                    HorizontalDivider()
                    SettingRow(
                        "Weight",
                        if (ui.useMetric) String.format(Locale.US, "%.1f kg", p.weightKg)
                        else String.format(Locale.US, "%.1f lbs", p.weightKg * 2.20462)
                    ) { sheet = SettingsSheet.WEIGHT }
                    HorizontalDivider()
                    SettingRow(
                        "Body fat",
                        p.bodyFatPercentage?.let { "${(it * 100).toInt()}%" } ?: "Not set"
                    ) { sheet = SettingsSheet.BODY_FAT }
                    HorizontalDivider()
                    SettingRow("Activity", p.activityLevel.displayName) { sheet = SettingsSheet.ACTIVITY }
                    HorizontalDivider()
                    SettingRow("Goal", p.goal.displayName) { sheet = SettingsSheet.GOAL }
                    if (p.goal != WeightGoal.MAINTAIN) {
                        HorizontalDivider()
                        SettingRow(
                            "Target weight",
                            p.goalWeightKg?.let {
                                if (ui.useMetric) String.format(Locale.US, "%.1f kg", it)
                                else String.format(Locale.US, "%.1f lbs", it * 2.20462)
                            } ?: "Not set"
                        ) { sheet = SettingsSheet.GOAL_WEIGHT }
                        HorizontalDivider()
                        SettingRow(
                            "Goal speed",
                            p.weeklyChangeKg?.let {
                                if (ui.useMetric) String.format(Locale.US, "%.2f kg/wk", it)
                                else String.format(Locale.US, "%.2f lbs/wk", it * 2.20462)
                            } ?: "0.50 kg/wk"
                        ) { sheet = SettingsSheet.GOAL_SPEED }
                    }
                }
            }

            SectionCard(title = "Goals") {
                profile?.let { p ->
                    SettingRow("Calories", "${p.effectiveCalories} kcal") { sheet = SettingsSheet.MACROS }
                    HorizontalDivider()
                    SettingRow("Protein", "${p.effectiveProtein} g") { sheet = SettingsSheet.MACROS }
                    HorizontalDivider()
                    SettingRow("Carbs", "${p.effectiveCarbs} g") { sheet = SettingsSheet.MACROS }
                    HorizontalDivider()
                    SettingRow("Fat", "${p.effectiveFat} g") { sheet = SettingsSheet.MACROS }
                    HorizontalDivider()
                    TextButton(
                        onClick = { showRecalcDialog = true },
                        modifier = Modifier.fillMaxWidth().padding(4.dp)
                    ) { Text("Recalculate goals from formula", color = AppColors.Calorie) }
                }
            }

            SectionCard(title = "AI Provider") {
                SettingRow("Provider", ui.selectedAI.displayName) { sheet = SettingsSheet.AI_PROVIDER }
                HorizontalDivider()
                if (ui.selectedAI.requiresCustomEndpoint) {
                    SettingRow("Base URL", "Tap to edit") { sheet = SettingsSheet.CUSTOM_BASE_URL }
                    HorizontalDivider()
                }
                SettingRow("Model", ui.selectedModel.ifEmpty { "(set one below)" }) { sheet = SettingsSheet.AI_MODEL }
                HorizontalDivider()
                SettingRow("API Key", ui.apiKeyMasked.ifEmpty { "Not set" }) { sheet = SettingsSheet.API_KEY }
            }

            SectionCard(title = "Speech") {
                SettingRow("STT Engine", ui.selectedSpeech.displayName) { sheet = SettingsSheet.SPEECH_PROVIDER }
                if (ui.selectedSpeech.requiresApiKey) {
                    HorizontalDivider()
                    SettingRow("API Key", "Tap to edit") { sheet = SettingsSheet.SPEECH_KEY }
                }
            }

            SectionCard(title = "Units") {
                ToggleRow("Use metric (kg / cm)", ui.useMetric, vm::setUseMetric)
            }

            SectionCard(title = "Notifications") {
                ToggleRow("Enable reminders", ui.notificationsEnabled, vm::setNotificationsEnabled)
            }

            SectionCard(title = "Health Connect") {
                ToggleRow("Sync to Health Connect", ui.healthConnectEnabled, vm::setHealthConnectEnabled)
            }

            SectionCard(title = "Danger zone") {
                TextButton(onClick = { showClearFoodDialog = true }, modifier = Modifier.fillMaxWidth().padding(4.dp)) {
                    Text("Clear food log", color = IOSColors.systemRed())
                }
                HorizontalDivider()
                TextButton(onClick = { showDeleteDialog = true }, modifier = Modifier.fillMaxWidth().padding(4.dp)) {
                    Text("Delete all local data", color = IOSColors.systemRed())
                }
            }

            Spacer(Modifier.height(16.dp))
        }
    }

    sheet?.let { s ->
        SettingsSheets(
            sheet = s,
            ui = ui,
            vm = vm,
            onDismiss = { sheet = null }
        )
    }

    if (showClearFoodDialog) {
        AlertDialog(
            onDismissRequest = { showClearFoodDialog = false },
            title = { Text("Clear food log?") },
            text = { Text("Wipes all food entries and photos. Profile, weights, and settings stay.") },
            confirmButton = {
                TextButton(onClick = { vm.clearFoodLog(); showClearFoodDialog = false }) {
                    Text("Clear", color = IOSColors.systemRed())
                }
            },
            dismissButton = { TextButton(onClick = { showClearFoodDialog = false }) { Text("Cancel") } }
        )
    }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Delete all local data?") },
            text = { Text("Wipes profile, food log, weight history, chat, and API keys. Health Connect data stays intact.") },
            confirmButton = {
                TextButton(onClick = { vm.deleteAllData(); showDeleteDialog = false }) {
                    Text("Delete", color = IOSColors.systemRed())
                }
            },
            dismissButton = { TextButton(onClick = { showDeleteDialog = false }) { Text("Cancel") } }
        )
    }

    if (showRecalcDialog) {
        AlertDialog(
            onDismissRequest = { showRecalcDialog = false },
            title = { Text("Recalculate goals?") },
            text = { Text("Resets calories and macros to formula defaults from your height/weight/activity/goal. Any pinned macros are cleared.") },
            confirmButton = { TextButton(onClick = { vm.recalculateGoals(); showRecalcDialog = false }) { Text("Recalculate") } },
            dismissButton = { TextButton(onClick = { showRecalcDialog = false }) { Text("Cancel") } }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SettingsSheets(sheet: SettingsSheet, ui: SettingsUiState, vm: SettingsViewModel, onDismiss: () -> Unit) {
    val state = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = state, shape = RoundedCornerShape(28.dp)) {
        Column(Modifier.fillMaxWidth().padding(horizontal = 20.dp, vertical = 8.dp)) {
            when (sheet) {
                SettingsSheet.AI_PROVIDER -> ListSheet(
                    title = "AI Provider",
                    items = AIProvider.values().toList(),
                    label = { it.displayName },
                    selected = { it == ui.selectedAI },
                    onSelect = { vm.selectProvider(it); onDismiss() }
                )
                SettingsSheet.AI_MODEL -> ListSheet(
                    title = "Model",
                    items = ui.selectedAI.models,
                    label = { it },
                    selected = { it == ui.selectedModel },
                    onSelect = { vm.selectModel(it); onDismiss() },
                    footer = if (ui.selectedAI.supportsCustomModelName) "Or type any custom model ID below." else null,
                    customField = if (ui.selectedAI.supportsCustomModelName) {
                        { m -> vm.selectModel(m); onDismiss() }
                    } else null
                )
                SettingsSheet.API_KEY -> ApiKeySheet(
                    title = "API Key — ${ui.selectedAI.displayName}",
                    placeholder = ui.selectedAI.apiKeyPlaceholder,
                    onSave = { vm.setApiKey(it); onDismiss() }
                )
                SettingsSheet.CUSTOM_BASE_URL -> {
                    val existing = remember { runBlocking { vm.container.prefs.customBaseUrl(ui.selectedAI).first().orEmpty() } }
                    TextFieldSheet(
                        title = "Custom base URL",
                        initial = existing,
                        placeholder = "https://your-endpoint.com/v1",
                        onSave = { vm.setCustomBaseUrl(ui.selectedAI, it); onDismiss() }
                    )
                }
                SettingsSheet.SPEECH_PROVIDER -> ListSheet(
                    title = "Speech Engine",
                    items = SpeechProvider.values().toList(),
                    label = { it.displayName },
                    selected = { it == ui.selectedSpeech },
                    onSelect = { vm.selectSpeech(it); onDismiss() }
                )
                SettingsSheet.SPEECH_KEY -> ApiKeySheet(
                    title = "Speech API Key — ${ui.selectedSpeech.displayName}",
                    placeholder = ui.selectedSpeech.apiKeyPlaceholder,
                    onSave = {
                        val key = it.takeIf { s -> s.isNotBlank() }
                        vm.container.keyStore.setSpeechApiKey(ui.selectedSpeech, key)
                        onDismiss()
                    }
                )
                SettingsSheet.GENDER -> ListSheet(
                    title = "Gender",
                    items = Gender.values().toList(),
                    label = { it.displayName },
                    selected = { it == ui.profile?.gender },
                    onSelect = { g -> vm.updateProfile { it.copy(gender = g) }; onDismiss() }
                )
                SettingsSheet.HEIGHT -> {
                    val cm = ui.profile?.heightCm?.toInt() ?: 175
                    HeightSheet(
                        current = cm,
                        useMetric = ui.useMetric,
                        onSave = { newCm -> vm.updateProfile { it.copy(heightCm = newCm.toDouble()) }; onDismiss() }
                    )
                }
                SettingsSheet.WEIGHT -> {
                    val kg = ui.profile?.weightKg ?: 70.0
                    WeightSheet(
                        titleText = "Weight",
                        current = kg,
                        useMetric = ui.useMetric,
                        onSave = { newKg -> vm.updateProfile { it.copy(weightKg = newKg) }; onDismiss() }
                    )
                }
                SettingsSheet.BODY_FAT -> BodyFatSheet(
                    current = ui.profile?.bodyFatPercentage,
                    onSave = { bf -> vm.updateProfile { it.copy(bodyFatPercentage = bf) }; onDismiss() }
                )
                SettingsSheet.ACTIVITY -> ListSheet(
                    title = "Activity level",
                    items = ActivityLevel.values().toList(),
                    label = { "${it.displayName} · ${it.subtitle}" },
                    selected = { it == ui.profile?.activityLevel },
                    onSelect = { a -> vm.updateProfile { it.copy(activityLevel = a) }; onDismiss() }
                )
                SettingsSheet.GOAL -> ListSheet(
                    title = "Goal",
                    items = WeightGoal.values().toList(),
                    label = { it.displayName },
                    selected = { it == ui.profile?.goal },
                    onSelect = { g ->
                        vm.updateProfile { it.copy(goal = g) }
                        onDismiss()
                    }
                )
                SettingsSheet.GOAL_WEIGHT -> {
                    val kg = ui.profile?.goalWeightKg ?: (ui.profile?.weightKg ?: 70.0)
                    WeightSheet(
                        titleText = "Target weight",
                        current = kg,
                        useMetric = ui.useMetric,
                        onSave = { newKg -> vm.updateProfile { it.copy(goalWeightKg = newKg) }; onDismiss() }
                    )
                }
                SettingsSheet.GOAL_SPEED -> GoalSpeedSheet(
                    current = ui.profile?.weeklyChangeKg ?: 0.5,
                    useMetric = ui.useMetric,
                    onSave = { kg -> vm.updateProfile { it.copy(weeklyChangeKg = kg) }; onDismiss() }
                )
                SettingsSheet.MACROS -> MacrosSheet(
                    profile = ui.profile,
                    onSaveCalories = { cal -> vm.updateProfile { it.copy(customCalories = cal) } },
                    onSaveMacro = { macro, grams ->
                        vm.updateProfile {
                            when (macro) {
                                AutoBalanceMacro.PROTEIN -> it.copy(customProtein = grams)
                                AutoBalanceMacro.CARBS -> it.copy(customCarbs = grams)
                                AutoBalanceMacro.FAT -> it.copy(customFat = grams)
                            }
                        }
                    },
                    onClearPin = { macro ->
                        vm.updateProfile {
                            when (macro) {
                                AutoBalanceMacro.PROTEIN -> it.copy(customProtein = null)
                                AutoBalanceMacro.CARBS -> it.copy(customCarbs = null)
                                AutoBalanceMacro.FAT -> it.copy(customFat = null)
                            }
                        }
                    }
                )
            }
            Spacer(Modifier.height(14.dp))
        }
    }
}

@Composable
private fun <T> ListSheet(
    title: String,
    items: List<T>,
    label: (T) -> String,
    selected: (T) -> Boolean,
    onSelect: (T) -> Unit,
    footer: String? = null,
    customField: ((String) -> Unit)? = null
) {
    Text(title, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
    Spacer(Modifier.height(10.dp))
    LazyColumn(Modifier.fillMaxWidth().heightIn(max = 360.dp), verticalArrangement = Arrangement.spacedBy(4.dp)) {
        items(items) { item ->
            val isSel = selected(item)
            Box(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(12.dp))
                    .background(if (isSel) AppColors.Calorie.copy(alpha = 0.15f) else Color.Transparent)
                    .clickable { onSelect(item) }
                    .padding(horizontal = 14.dp, vertical = 14.dp)
            ) {
                Text(label(item), style = MaterialTheme.typography.bodyLarge)
            }
        }
    }
    if (customField != null) {
        footer?.let {
            Spacer(Modifier.height(8.dp))
            Text(it, style = MaterialTheme.typography.bodySmall, color = IOSColors.secondaryLabel())
        }
        var custom by remember { mutableStateOf("") }
        Spacer(Modifier.height(8.dp))
        OutlinedTextField(
            value = custom,
            onValueChange = { custom = it },
            placeholder = { Text("Any model ID") },
            modifier = Modifier.fillMaxWidth()
        )
        Spacer(Modifier.height(8.dp))
        Button(
            onClick = { if (custom.isNotBlank()) customField(custom.trim()) },
            colors = ButtonDefaults.buttonColors(containerColor = AppColors.Calorie),
            modifier = Modifier.fillMaxWidth()
        ) { Text("Save", color = Color.White) }
    }
}

@Composable
private fun ApiKeySheet(title: String, placeholder: String, onSave: (String) -> Unit) {
    var value by remember { mutableStateOf("") }
    Text(title, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
    Spacer(Modifier.height(12.dp))
    OutlinedTextField(
        value = value,
        onValueChange = { value = it },
        placeholder = { Text(placeholder) },
        visualTransformation = PasswordVisualTransformation(),
        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
        singleLine = true,
        modifier = Modifier.fillMaxWidth()
    )
    Spacer(Modifier.height(12.dp))
    Button(
        onClick = { onSave(value) },
        colors = ButtonDefaults.buttonColors(containerColor = AppColors.Calorie),
        modifier = Modifier.fillMaxWidth()
    ) { Text("Save", color = Color.White) }
    Spacer(Modifier.height(4.dp))
    TextButton(onClick = { onSave("") }, modifier = Modifier.fillMaxWidth()) { Text("Clear key") }
}

@Composable
private fun TextFieldSheet(title: String, initial: String, placeholder: String, onSave: (String) -> Unit) {
    var value by remember { mutableStateOf(initial) }
    Text(title, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
    Spacer(Modifier.height(12.dp))
    OutlinedTextField(
        value = value,
        onValueChange = { value = it },
        placeholder = { Text(placeholder) },
        singleLine = true,
        modifier = Modifier.fillMaxWidth()
    )
    Spacer(Modifier.height(12.dp))
    Button(
        onClick = { onSave(value.trim()) },
        colors = ButtonDefaults.buttonColors(containerColor = AppColors.Calorie),
        modifier = Modifier.fillMaxWidth()
    ) { Text("Save", color = Color.White) }
}

@Composable
private fun HeightSheet(current: Int, useMetric: Boolean, onSave: (Int) -> Unit) {
    var cm by remember(current) { mutableStateOf(current) }
    var metric by remember { mutableStateOf(useMetric) }
    Text("Height", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
    Spacer(Modifier.height(12.dp))
    UnitToggle("cm", "ft / in", metric, { metric = it }, Modifier.fillMaxWidth())
    Spacer(Modifier.height(20.dp))
    if (metric) NumericWheelPicker(cm, { cm = it }, 100, 250, "cm")
    else FeetInchesWheelPicker(cm, { cm = it })
    Spacer(Modifier.height(16.dp))
    Button(
        onClick = { onSave(cm) },
        colors = ButtonDefaults.buttonColors(containerColor = AppColors.Calorie),
        modifier = Modifier.fillMaxWidth()
    ) { Text("Save", color = Color.White) }
}

@Composable
private fun WeightSheet(titleText: String, current: Double, useMetric: Boolean, onSave: (Double) -> Unit) {
    var kg by remember(current) { mutableStateOf(current) }
    var metric by remember { mutableStateOf(useMetric) }
    Text(titleText, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
    Spacer(Modifier.height(12.dp))
    UnitToggle("kg", "lbs", metric, { metric = it }, Modifier.fillMaxWidth())
    Spacer(Modifier.height(20.dp))
    if (metric) {
        SplitDecimalWheelPicker(kg, { kg = it }, 30, 250, "kg")
    } else {
        SplitDecimalWheelPicker(kg * 2.20462, { lbs -> kg = lbs / 2.20462 }, 66, 551, "lbs")
    }
    Spacer(Modifier.height(16.dp))
    Button(
        onClick = { onSave(kg) },
        colors = ButtonDefaults.buttonColors(containerColor = AppColors.Calorie),
        modifier = Modifier.fillMaxWidth()
    ) { Text("Save", color = Color.White) }
}

@Composable
private fun BodyFatSheet(current: Double?, onSave: (Double?) -> Unit) {
    var pct by remember(current) { mutableStateOf((current ?: 0.20) * 100) }
    Text("Body fat %", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
    Spacer(Modifier.height(12.dp))
    DecimalWheelPicker(pct, { pct = it }, 5.0, 60.0, 0.5, "%")
    Spacer(Modifier.height(12.dp))
    Row {
        Button(
            onClick = { onSave(pct / 100.0) },
            colors = ButtonDefaults.buttonColors(containerColor = AppColors.Calorie),
            modifier = Modifier.weight(1f)
        ) { Text("Save", color = Color.White) }
        Spacer(Modifier.height(8.dp))
        TextButton(
            onClick = { onSave(null) },
            modifier = Modifier.weight(1f)
        ) { Text("Clear") }
    }
}

@Composable
private fun GoalSpeedSheet(current: Double, useMetric: Boolean, onSave: (Double) -> Unit) {
    Text("Goal speed", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
    Spacer(Modifier.height(8.dp))
    val options = listOf(0.25 to "Slow & steady", 0.5 to "Moderate", 1.0 to "Fast")
    for ((kg, label) in options) {
        val isSel = kotlin.math.abs(kg - current) < 0.01
        Box(
            Modifier
                .fillMaxWidth()
                .padding(vertical = 4.dp)
                .clip(RoundedCornerShape(14.dp))
                .background(if (isSel) AppColors.Calorie.copy(alpha = 0.15f) else Color.Transparent)
                .clickable { onSave(kg) }
                .padding(horizontal = 16.dp, vertical = 14.dp)
        ) {
            val display = if (useMetric) String.format(Locale.US, "%.2f kg/week", kg)
                          else String.format(Locale.US, "%.2f lbs/week", kg * 2.20462)
            Text("$label · $display", fontWeight = FontWeight.SemiBold)
        }
    }
}

@Composable
private fun MacrosSheet(
    profile: com.apoorvdarshan.calorietracker.models.UserProfile?,
    onSaveCalories: (Int?) -> Unit,
    onSaveMacro: (AutoBalanceMacro, Int?) -> Unit,
    onClearPin: (AutoBalanceMacro) -> Unit
) {
    profile ?: return
    var caloriesText by remember(profile) { mutableStateOf(profile.effectiveCalories.toString()) }
    var proteinText by remember(profile) { mutableStateOf(profile.effectiveProtein.toString()) }
    var carbsText by remember(profile) { mutableStateOf(profile.effectiveCarbs.toString()) }
    var fatText by remember(profile) { mutableStateOf(profile.effectiveFat.toString()) }
    Text("Macros", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
    Text(
        "Pin up to 2 macros to exact grams. Unpinned ones auto-balance from remaining calories.",
        style = MaterialTheme.typography.bodySmall,
        color = IOSColors.secondaryLabel()
    )
    Spacer(Modifier.height(12.dp))
    MacroField("Calories", caloriesText, { caloriesText = it }, "kcal") {
        caloriesText.toIntOrNull()?.let { onSaveCalories(it) }
    }
    Spacer(Modifier.height(6.dp))
    MacroField(
        label = "Protein (${if (profile.isPinned(AutoBalanceMacro.PROTEIN)) "pinned" else "auto"})",
        value = proteinText,
        onChange = { proteinText = it },
        unit = "g",
        pinned = profile.isPinned(AutoBalanceMacro.PROTEIN),
        onClearPin = { onClearPin(AutoBalanceMacro.PROTEIN) }
    ) { proteinText.toIntOrNull()?.let { onSaveMacro(AutoBalanceMacro.PROTEIN, it) } }
    Spacer(Modifier.height(6.dp))
    MacroField(
        label = "Carbs (${if (profile.isPinned(AutoBalanceMacro.CARBS)) "pinned" else "auto"})",
        value = carbsText,
        onChange = { carbsText = it },
        unit = "g",
        pinned = profile.isPinned(AutoBalanceMacro.CARBS),
        onClearPin = { onClearPin(AutoBalanceMacro.CARBS) }
    ) { carbsText.toIntOrNull()?.let { onSaveMacro(AutoBalanceMacro.CARBS, it) } }
    Spacer(Modifier.height(6.dp))
    MacroField(
        label = "Fat (${if (profile.isPinned(AutoBalanceMacro.FAT)) "pinned" else "auto"})",
        value = fatText,
        onChange = { fatText = it },
        unit = "g",
        pinned = profile.isPinned(AutoBalanceMacro.FAT),
        onClearPin = { onClearPin(AutoBalanceMacro.FAT) }
    ) { fatText.toIntOrNull()?.let { onSaveMacro(AutoBalanceMacro.FAT, it) } }
}

@Composable
private fun MacroField(
    label: String,
    value: String,
    onChange: (String) -> Unit,
    unit: String,
    pinned: Boolean = false,
    onClearPin: (() -> Unit)? = null,
    onPin: () -> Unit
) {
    Row(verticalAlignment = Alignment.CenterVertically) {
        OutlinedTextField(
            value = value,
            onValueChange = onChange,
            label = { Text(label) },
            suffix = { Text(unit) },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            singleLine = true,
            modifier = Modifier.weight(1f)
        )
        Spacer(Modifier.height(6.dp))
        TextButton(onClick = { if (pinned) onClearPin?.invoke() else onPin() }) {
            Text(if (pinned) "Clear" else "Pin", color = AppColors.Calorie)
        }
    }
}

@Composable
private fun SectionCard(title: String, content: @Composable () -> Unit) {
    Column {
        Text(
            title.uppercase(),
            style = MaterialTheme.typography.labelSmall,
            color = IOSColors.secondaryLabel(),
            modifier = Modifier.padding(start = 4.dp, bottom = 6.dp)
        )
        Card(
            shape = RoundedCornerShape(18.dp),
            colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
        ) {
            Column(Modifier.padding(vertical = 4.dp)) { content() }
        }
    }
}

@Composable
private fun SettingRow(label: String, value: String, onClick: () -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label, modifier = Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge)
        Text(value, style = MaterialTheme.typography.bodyMedium, color = IOSColors.secondaryLabel())
        Icon(Icons.Filled.ChevronRight, contentDescription = null, tint = IOSColors.tertiaryLabel())
    }
}

@Composable
private fun ToggleRow(label: String, checked: Boolean, onChange: (Boolean) -> Unit) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label, modifier = Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge)
        Switch(checked = checked, onCheckedChange = onChange)
    }
}

private fun feetInchesLabel(cm: Int): String {
    val totalInches = (cm / 2.54).toInt()
    val feet = totalInches / 12
    val inches = totalInches % 12
    return "$feet' $inches\""
}
