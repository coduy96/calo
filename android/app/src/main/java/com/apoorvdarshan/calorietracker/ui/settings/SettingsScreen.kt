package com.apoorvdarshan.calorietracker.ui.settings

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
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
import androidx.compose.material.icons.automirrored.outlined.DirectionsRun
import androidx.compose.material.icons.filled.Check
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.UnfoldMore
import androidx.compose.material.icons.automirrored.outlined.DirectionsWalk
import androidx.compose.material.icons.outlined.FitnessCenter
import androidx.compose.material.icons.outlined.LocalDining
import androidx.compose.material.icons.outlined.SelfImprovement
import androidx.compose.material.icons.outlined.SportsMartialArts
import androidx.compose.material.icons.outlined.DarkMode
import androidx.compose.material.icons.outlined.LightMode
import androidx.compose.material.icons.outlined.SettingsBrightness
import androidx.compose.material.icons.outlined.Wc
import androidx.compose.material.icons.outlined.Female
import androidx.compose.material.icons.outlined.Male
import androidx.compose.material.icons.automirrored.filled.TrendingDown
import androidx.compose.material.icons.automirrored.filled.TrendingFlat
import androidx.compose.material.icons.outlined.Brightness6
import androidx.compose.material.icons.outlined.CalendarToday
import androidx.compose.material.icons.outlined.Cake
import androidx.compose.material.icons.outlined.DataUsage
import androidx.compose.material.icons.outlined.DeleteForever
import androidx.compose.material.icons.outlined.DeleteSweep
import androidx.compose.material.icons.outlined.Equalizer
import androidx.compose.material.icons.outlined.Favorite
import androidx.compose.material.icons.outlined.GraphicEq
import androidx.compose.material.icons.outlined.Height
import androidx.compose.material.icons.outlined.Key
import androidx.compose.material.icons.outlined.Language
import androidx.compose.material.icons.outlined.Link
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.outlined.LockOpen
import androidx.compose.material.icons.outlined.LocalFireDepartment
import androidx.compose.material.icons.outlined.Mic
import androidx.compose.material.icons.outlined.MonitorWeight
import androidx.compose.material.icons.outlined.Notifications
import androidx.compose.material.icons.outlined.Percent
import androidx.compose.material.icons.outlined.Person
import androidx.compose.material.icons.outlined.Refresh
import androidx.compose.material.icons.outlined.SmartToy
import androidx.compose.material.icons.outlined.Speed
import androidx.compose.material.icons.outlined.Straighten
import androidx.compose.material.icons.automirrored.outlined.TrendingUp
import androidx.compose.material.icons.outlined.Tune
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.DatePicker
import androidx.compose.material3.DatePickerDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.rememberDatePickerState
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import com.apoorvdarshan.calorietracker.AppContainer
import com.apoorvdarshan.calorietracker.models.ActivityLevel
import com.apoorvdarshan.calorietracker.models.AIProvider
import com.apoorvdarshan.calorietracker.models.AutoBalanceMacro
import com.apoorvdarshan.calorietracker.models.Gender
import com.apoorvdarshan.calorietracker.models.SpeechProvider
import com.apoorvdarshan.calorietracker.models.UserProfile
import com.apoorvdarshan.calorietracker.models.WeightGoal
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.time.format.DateTimeFormatter
import com.apoorvdarshan.calorietracker.ui.components.DecimalWheelPicker
import com.apoorvdarshan.calorietracker.ui.components.FeetInchesWheelPicker
import com.apoorvdarshan.calorietracker.ui.components.NumericWheelPicker
import com.apoorvdarshan.calorietracker.ui.components.SplitDecimalWheelPicker
import com.apoorvdarshan.calorietracker.ui.components.UnitToggle
import com.apoorvdarshan.calorietracker.ui.theme.AppColors
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.runBlocking
import java.util.Locale

private enum class SettingsSheet {
    AI_PROVIDER, AI_MODEL, API_KEY, CUSTOM_BASE_URL, SPEECH_PROVIDER, SPEECH_KEY,
    GENDER, BIRTHDAY, HEIGHT, WEIGHT, BODY_FAT, ACTIVITY, GOAL, GOAL_WEIGHT, GOAL_SPEED, MACROS,
    APPEARANCE, WEEK_START
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
    var invalidGoalWeightMessage by remember { mutableStateOf<String?>(null) }

    // iOS Settings: bare List, no NavigationBar visible. Match that — no TopAppBar.
    Scaffold(containerColor = MaterialTheme.colorScheme.background) { padding ->
        Column(
            Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(14.dp)
        ) {
            // Section 1 — Personal Info (matches iOS Section "Personal Info")
            SectionCard(title = "Personal Info") {
                profile?.let { p ->
                    SettingRow("Gender", p.gender.displayName, icon = Icons.Outlined.Person, inlineMenu = true) { sheet = SettingsSheet.GENDER }
                    HorizontalDivider()
                    SettingRow("Birthday", birthdayDisplay(p), icon = Icons.Outlined.Cake) { sheet = SettingsSheet.BIRTHDAY }
                    HorizontalDivider()
                    SettingRow(
                        "Height",
                        if (ui.useMetric) "${p.heightCm.toInt()} cm"
                        else feetInchesLabel(p.heightCm.toInt()),
                        icon = Icons.Outlined.Height
                    ) { sheet = SettingsSheet.HEIGHT }
                    HorizontalDivider()
                    SettingRow(
                        "Weight",
                        if (ui.useMetric) String.format(Locale.US, "%.1f kg", p.weightKg)
                        else String.format(Locale.US, "%.1f lbs", p.weightKg * 2.20462),
                        icon = Icons.Outlined.MonitorWeight
                    ) { sheet = SettingsSheet.WEIGHT }
                    HorizontalDivider()
                    SettingRow(
                        "Body Fat",
                        p.bodyFatPercentage?.let { "${(it * 100).toInt()}%" } ?: "Not set",
                        icon = Icons.Outlined.Percent
                    ) { sheet = SettingsSheet.BODY_FAT }
                }
            }

            // Section 2 — Goals & Nutrition (matches iOS Section "Goals & Nutrition")
            SectionCard(title = "Goals & Nutrition") {
                profile?.let { p ->
                    SettingRow("Weight Goal", p.goal.displayName, icon = Icons.Outlined.Equalizer, inlineMenu = true) { sheet = SettingsSheet.GOAL }
                    HorizontalDivider()
                    SettingRow("Activity Level", p.activityLevel.displayName, icon = Icons.AutoMirrored.Outlined.DirectionsRun, inlineMenu = true) { sheet = SettingsSheet.ACTIVITY }
                    if (p.goal != WeightGoal.MAINTAIN) {
                        HorizontalDivider()
                        SettingRow(
                            "Weekly Change",
                            p.weeklyChangeKg?.let {
                                if (ui.useMetric) String.format(Locale.US, "%.2f kg/wk", it)
                                else String.format(Locale.US, "%.2f lbs/wk", it * 2.20462)
                            } ?: "0.50 kg/wk",
                            icon = Icons.Outlined.Speed
                        ) { sheet = SettingsSheet.GOAL_SPEED }
                        HorizontalDivider()
                        SettingRow(
                            "Goal Weight",
                            p.goalWeightKg?.let {
                                if (ui.useMetric) String.format(Locale.US, "%.1f kg", it)
                                else String.format(Locale.US, "%.1f lbs", it * 2.20462)
                            } ?: "Not set",
                            icon = Icons.AutoMirrored.Outlined.TrendingUp
                        ) { sheet = SettingsSheet.GOAL_WEIGHT }
                    }
                    HorizontalDivider()
                    // iOS shows "2452 kcal" with no chevron suffix on the Calories row.
                    SettingRow("Calories", "${p.effectiveCalories} kcal", icon = Icons.Outlined.LocalFireDepartment) { sheet = SettingsSheet.MACROS }
                    HorizontalDivider()
                    // Per-macro rows mirror iOS macroRow(): "{value}g · auto" suffix when
                    // unpinned, "{value}g" when pinned, plus lock.fill / lock.open icon.
                    MacroSettingRow(
                        label = "Protein",
                        value = p.effectiveProtein,
                        pinned = p.isPinned(AutoBalanceMacro.PROTEIN),
                        onClick = { sheet = SettingsSheet.MACROS }
                    )
                    HorizontalDivider()
                    MacroSettingRow(
                        label = "Carbs",
                        value = p.effectiveCarbs,
                        pinned = p.isPinned(AutoBalanceMacro.CARBS),
                        onClick = { sheet = SettingsSheet.MACROS }
                    )
                    HorizontalDivider()
                    MacroSettingRow(
                        label = "Fat",
                        value = p.effectiveFat,
                        pinned = p.isPinned(AutoBalanceMacro.FAT),
                        onClick = { sheet = SettingsSheet.MACROS }
                    )
                    HorizontalDivider()
                    Row(
                        Modifier
                            .fillMaxWidth()
                            .clickable { showRecalcDialog = true }
                            .padding(horizontal = 16.dp, vertical = 14.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Icon(
                            Icons.Outlined.Refresh,
                            contentDescription = null,
                            tint = AppColors.Calorie,
                            modifier = Modifier.size(22.dp)
                        )
                        Spacer(Modifier.width(14.dp))
                        Text("Recalculate Goals", color = AppColors.Calorie, style = MaterialTheme.typography.bodyLarge)
                    }
                }
            }

            // Section 3 — App Settings (matches iOS Section "App Settings")
            SectionCard(title = "App Settings") {
                SettingRow(
                    "Appearance",
                    when (ui.appearanceMode) {
                        "light" -> "Light"
                        "dark" -> "Dark"
                        else -> "System"
                    },
                    icon = Icons.Outlined.Brightness6
                ) { sheet = SettingsSheet.APPEARANCE }
                HorizontalDivider()
                ToggleRow("Metric Units", ui.useMetric, icon = Icons.Outlined.Straighten, onChange = vm::setUseMetric)
                HorizontalDivider()
                SettingRow(
                    "Week Starts On",
                    if (ui.weekStartsOnMonday) "Monday" else "Sunday",
                    icon = Icons.Outlined.CalendarToday
                ) { sheet = SettingsSheet.WEEK_START }
                HorizontalDivider()
                ToggleRow("Notifications", ui.notificationsEnabled, icon = Icons.Outlined.Notifications, onChange = vm::setNotificationsEnabled)
            }

            // Section 4 — AI Provider (matches iOS Section "AI Provider")
            SectionCard(title = "AI Provider") {
                SettingRow("Provider", ui.selectedAI.displayName, icon = Icons.Outlined.SmartToy) { sheet = SettingsSheet.AI_PROVIDER }
                HorizontalDivider()
                SettingRow("Model", ui.selectedModel.ifEmpty { "(set one below)" }, icon = Icons.Outlined.Tune) { sheet = SettingsSheet.AI_MODEL }
                if (ui.selectedAI.requiresApiKey) {
                    HorizontalDivider()
                    SettingRow("API Key", ui.apiKeyMasked.ifEmpty { "Not set" }, icon = Icons.Outlined.Key) { sheet = SettingsSheet.API_KEY }
                }
                if (ui.selectedAI.requiresCustomEndpoint || ui.selectedAI == AIProvider.OLLAMA) {
                    HorizontalDivider()
                    SettingRow(
                        if (ui.selectedAI.requiresCustomEndpoint) "Base URL" else "Server URL",
                        "Tap to edit",
                        icon = Icons.Outlined.Link
                    ) { sheet = SettingsSheet.CUSTOM_BASE_URL }
                }
            }

            // Section 5 — Speech-to-Text (matches iOS Section "Speech-to-Text")
            SectionCard(title = "Speech-to-Text") {
                SettingRow("Provider", ui.selectedSpeech.displayName, icon = Icons.Outlined.Mic) { sheet = SettingsSheet.SPEECH_PROVIDER }
                HorizontalDivider()
                Text(
                    ui.selectedSpeech.description,
                    fontSize = 12.sp,
                    color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f),
                    modifier = Modifier.padding(horizontal = 16.dp, vertical = 10.dp)
                )
                if (ui.selectedSpeech.requiresApiKey) {
                    HorizontalDivider()
                    SettingRow("API Key", "Tap to edit", icon = Icons.Outlined.Key) { sheet = SettingsSheet.SPEECH_KEY }
                }
            }

            // Section 6 — Health & Data (matches iOS Section "Health & Data")
            SectionCard(title = "Health & Data") {
                ToggleRow("Health Connect", ui.healthConnectEnabled, icon = Icons.Outlined.Favorite, onChange = vm::setHealthConnectEnabled)
                HorizontalDivider()
                Row(
                    Modifier
                        .fillMaxWidth()
                        .clickable { showClearFoodDialog = true }
                        .padding(horizontal = 16.dp, vertical = 14.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(Icons.Outlined.DeleteSweep, contentDescription = null, tint = Color(0xFFFF9500), modifier = Modifier.size(22.dp))
                    Spacer(Modifier.width(14.dp))
                    Text("Clear Food Log", color = Color(0xFFFF9500), style = MaterialTheme.typography.bodyLarge)
                }
                HorizontalDivider()
                Row(
                    Modifier
                        .fillMaxWidth()
                        .clickable { showDeleteDialog = true }
                        .padding(horizontal = 16.dp, vertical = 14.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    Icon(Icons.Outlined.DeleteForever, contentDescription = null, tint = Color(0xFFFF3B30), modifier = Modifier.size(22.dp))
                    Spacer(Modifier.width(14.dp))
                    Text("Delete All Data", color = Color(0xFFFF3B30), style = MaterialTheme.typography.bodyLarge)
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
            onDismiss = { sheet = null },
            onInvalidGoalWeight = { invalidGoalWeightMessage = it }
        )
    }

    if (showClearFoodDialog) {
        AlertDialog(
            onDismissRequest = { showClearFoodDialog = false },
            title = { Text("Clear food log?") },
            text = { Text("Wipes all food entries and photos. Profile, weights, and settings stay.") },
            confirmButton = {
                TextButton(onClick = { vm.clearFoodLog(); showClearFoodDialog = false }) {
                    Text("Clear", color = Color(0xFFD32F2F))
                }
            },
            dismissButton = { TextButton(onClick = { showClearFoodDialog = false }) { Text("Cancel") } }
        )
    }

    if (showDeleteDialog) {
        val context = LocalContext.current
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Delete all local data?") },
            text = { Text("Wipes profile, food log, weight history, chat, and API keys, then takes you back to onboarding. Health Connect data stays intact.") },
            confirmButton = {
                TextButton(onClick = {
                    vm.deleteAllData {
                        showDeleteDialog = false
                        (context as? android.app.Activity)?.recreate()
                    }
                }) {
                    Text("Delete", color = Color(0xFFD32F2F))
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

    invalidGoalWeightMessage?.let { msg ->
        AlertDialog(
            onDismissRequest = { invalidGoalWeightMessage = null },
            title = { Text("Goal weight doesn't match your goal") },
            text = { Text(msg) },
            confirmButton = { TextButton(onClick = { invalidGoalWeightMessage = null }) { Text("OK") } }
        )
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun SettingsSheets(
    sheet: SettingsSheet,
    ui: SettingsUiState,
    vm: SettingsViewModel,
    onDismiss: () -> Unit,
    onInvalidGoalWeight: (String) -> Unit
) {
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
                    onSelect = { g -> vm.updateProfile { it.copy(gender = g) }; onDismiss() },
                    icon = { genderIcon(it) }
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
                        onSave = { newKg -> vm.saveCurrentWeight(newKg); onDismiss() }
                    )
                }
                SettingsSheet.BODY_FAT -> BodyFatSheet(
                    current = ui.profile?.bodyFatPercentage,
                    onSave = { bf -> vm.updateProfile { it.copy(bodyFatPercentage = bf) }; onDismiss() }
                )
                SettingsSheet.ACTIVITY -> ListSheet(
                    title = "Activity level",
                    items = ActivityLevel.values().toList(),
                    label = { it.displayName },
                    subtitle = { it.subtitle },
                    selected = { it == ui.profile?.activityLevel },
                    onSelect = { a -> vm.updateProfile { it.copy(activityLevel = a) }; onDismiss() },
                    icon = { activityIcon(it) }
                )
                SettingsSheet.GOAL -> ListSheet(
                    title = "Goal",
                    items = WeightGoal.values().toList(),
                    label = { it.displayName },
                    selected = { it == ui.profile?.goal },
                    icon = { goalIcon(it) },
                    onSelect = { g ->
                        // Mirrors iOS ContentView.swift profile.goal onChange:
                        //   - Switching to MAINTAIN clears weeklyChangeKg + goalWeightKg.
                        //   - Switching to LOSE/GAIN seeds weeklyChangeKg if missing and
                        //     clears goalWeightKg if it now contradicts the new direction.
                        vm.updateProfile { p ->
                            when (g) {
                                WeightGoal.MAINTAIN ->
                                    p.copy(goal = g, weeklyChangeKg = null, goalWeightKg = null)
                                else -> {
                                    val gw = p.goalWeightKg
                                    val mismatched = gw != null && (
                                        (g == WeightGoal.LOSE && gw >= p.weightKg) ||
                                        (g == WeightGoal.GAIN && gw <= p.weightKg)
                                    )
                                    p.copy(
                                        goal = g,
                                        weeklyChangeKg = p.weeklyChangeKg ?: 0.5,
                                        goalWeightKg = if (mismatched) null else p.goalWeightKg
                                    )
                                }
                            }
                        }
                        onDismiss()
                    }
                )
                SettingsSheet.GOAL_WEIGHT -> {
                    val kg = ui.profile?.goalWeightKg ?: (ui.profile?.weightKg ?: 70.0)
                    WeightSheet(
                        titleText = "Target weight",
                        current = kg,
                        useMetric = ui.useMetric,
                        onSave = { newKg ->
                            // Mirrors iOS ContentView.swift case .editGoalWeight: a Lose goal
                            // requires target < current weight; a Gain goal requires target >
                            // current weight. Reject mismatched targets with an alert instead
                            // of silently saving an unreachable goal.
                            val p = ui.profile
                            val current = p?.weightKg
                            val invalid = p != null && current != null && (
                                (p.goal == WeightGoal.LOSE && newKg >= current) ||
                                (p.goal == WeightGoal.GAIN && newKg <= current)
                            )
                            if (invalid) {
                                onInvalidGoalWeight(
                                    if (p!!.goal == WeightGoal.LOSE)
                                        "A Lose goal needs a target below your current weight."
                                    else
                                        "A Gain goal needs a target above your current weight."
                                )
                            } else {
                                vm.updateProfile { it.copy(goalWeightKg = newKg) }
                                onDismiss()
                            }
                        }
                    )
                }
                SettingsSheet.GOAL_SPEED -> GoalSpeedSheet(
                    current = ui.profile?.weeklyChangeKg ?: 0.5,
                    goal = ui.profile?.goal ?: WeightGoal.MAINTAIN,
                    useMetric = ui.useMetric,
                    onSave = { kg -> vm.updateProfile { it.copy(weeklyChangeKg = kg) }; onDismiss() }
                )
                SettingsSheet.BIRTHDAY -> BirthdaySheet(
                    current = ui.profile?.birthday ?: Instant.now(),
                    onSave = { newInstant ->
                        vm.updateProfile { it.copy(birthday = newInstant) }
                        onDismiss()
                    }
                )
                SettingsSheet.APPEARANCE -> ListSheet(
                    title = "Appearance",
                    items = listOf("system" to "System", "light" to "Light", "dark" to "Dark"),
                    label = { it.second },
                    selected = { it.first == ui.appearanceMode },
                    onSelect = { vm.setAppearanceMode(it.first); onDismiss() },
                    icon = { appearanceIcon(it.first) }
                )
                SettingsSheet.WEEK_START -> ListSheet(
                    title = "Week Starts On",
                    items = listOf(false to "Sunday", true to "Monday"),
                    label = { it.second },
                    selected = { it.first == ui.weekStartsOnMonday },
                    onSelect = { vm.setWeekStartsOnMonday(it.first); onDismiss() }
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
    icon: ((T) -> ImageVector?)? = null,
    subtitle: ((T) -> String?)? = null,
    footer: String? = null,
    customField: ((String) -> Unit)? = null
) {
    Text(title, style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
    Spacer(Modifier.height(12.dp))
    LazyColumn(Modifier.fillMaxWidth().heightIn(max = 420.dp), verticalArrangement = Arrangement.spacedBy(8.dp)) {
        items(items) { item ->
            val isSel = selected(item)
            val rowIcon = icon?.invoke(item)
            val sub = subtitle?.invoke(item)
            Row(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.45f))
                    .clickable { onSelect(item) }
                    .padding(horizontal = 14.dp, vertical = 14.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                if (rowIcon != null) {
                    Icon(rowIcon, contentDescription = null, tint = AppColors.Calorie, modifier = Modifier.size(22.dp))
                    Spacer(Modifier.width(14.dp))
                }
                Column(Modifier.weight(1f)) {
                    Text(
                        label(item),
                        style = MaterialTheme.typography.bodyLarge,
                        fontWeight = FontWeight.Medium
                    )
                    if (!sub.isNullOrBlank()) {
                        Spacer(Modifier.height(2.dp))
                        Text(
                            sub,
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                        )
                    }
                }
                if (isSel) {
                    Icon(
                        Icons.Filled.Check,
                        contentDescription = "Selected",
                        tint = AppColors.Calorie,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }
        }
    }
    if (customField != null) {
        footer?.let {
            Spacer(Modifier.height(8.dp))
            Text(it, style = MaterialTheme.typography.bodySmall, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f))
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
    GradientSaveButton { onSave(cm) }
    Spacer(Modifier.height(8.dp))
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
    GradientSaveButton { onSave(kg) }
    Spacer(Modifier.height(8.dp))
}

@Composable
private fun BodyFatSheet(current: Double?, onSave: (Double?) -> Unit) {
    var pct by remember(current) { mutableStateOf((current ?: 0.20) * 100) }
    Text("Body fat %", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
    Spacer(Modifier.height(12.dp))
    DecimalWheelPicker(pct, { pct = it }, 5.0, 60.0, 0.5, "%")
    Spacer(Modifier.height(12.dp))
    GradientSaveButton { onSave(pct / 100.0) }
    Spacer(Modifier.height(4.dp))
    TextButton(onClick = { onSave(null) }, modifier = Modifier.fillMaxWidth()) { Text("Clear") }
    Spacer(Modifier.height(8.dp))
}

@Composable
private fun GoalSpeedSheet(current: Double, goal: WeightGoal, useMetric: Boolean, onSave: (Double) -> Unit) {
    Text("Weekly Change", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
    Spacer(Modifier.height(12.dp))
    val unit = if (goal == WeightGoal.LOSE) "loss" else "gain"
    val options = listOf(
        Triple(0.25, "Slow", "0.25 ${if (useMetric) "kg" else "lbs"}/week $unit"),
        Triple(0.5, "Recommended", "0.5 ${if (useMetric) "kg" else "lbs"}/week $unit"),
        Triple(1.0, "Fast", "1.0 ${if (useMetric) "kg" else "lbs"}/week $unit")
    )
    Column(verticalArrangement = Arrangement.spacedBy(8.dp)) {
        for ((kg, title, subtitle) in options) {
            val isSel = kotlin.math.abs(kg - current) < 0.01
            Row(
                Modifier
                    .fillMaxWidth()
                    .clip(RoundedCornerShape(14.dp))
                    .background(MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.45f))
                    .clickable { onSave(kg) }
                    .padding(horizontal = 14.dp, vertical = 14.dp),
                verticalAlignment = Alignment.CenterVertically
            ) {
                Column(Modifier.weight(1f)) {
                    Text(title, style = MaterialTheme.typography.bodyLarge, fontWeight = FontWeight.Medium)
                    Spacer(Modifier.height(2.dp))
                    Text(
                        subtitle,
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
                    )
                }
                if (isSel) {
                    Icon(
                        Icons.Filled.Check,
                        contentDescription = "Selected",
                        tint = AppColors.Calorie,
                        modifier = Modifier.size(20.dp)
                    )
                }
            }
        }
    }
    Spacer(Modifier.height(8.dp))
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
        color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
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
    // iOS uses sentence-case section titles ("Personal Info", "Goals & Nutrition")
    // in a small grey caption. Match that — no uppercase transform.
    Column {
        Text(
            title,
            style = MaterialTheme.typography.labelMedium,
            color = MaterialTheme.colorScheme.onBackground.copy(alpha = 0.55f),
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
private fun SettingRow(
    label: String,
    value: String,
    icon: ImageVector? = null,
    // iOS `.menu` Picker rows render a `chevron.up.chevron.down` instead of a
    // right-chevron to signal the inline dropdown affordance. Pass inlineMenu=true
    // for Gender, Weight Goal, and Activity Level.
    inlineMenu: Boolean = false,
    onClick: () -> Unit
) {
    Row(
        Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (icon != null) {
            Icon(
                icon,
                contentDescription = null,
                tint = AppColors.Calorie,
                modifier = Modifier.size(22.dp)
            )
            Spacer(Modifier.width(14.dp))
        }
        Text(label, modifier = Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge)
        Text(value, style = MaterialTheme.typography.bodyMedium, color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f))
        Icon(
            if (inlineMenu) Icons.Filled.UnfoldMore else Icons.Filled.ChevronRight,
            contentDescription = null,
            tint = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.4f),
            modifier = if (inlineMenu) Modifier.size(18.dp) else Modifier
        )
    }
}

/**
 * Verbatim port of iOS `macroRow(label:icon:macro:value:sheet:)` in
 * ContentView.swift's ProfileView. Uses the DataUsage circle icon (matches
 * iOS circle.dotted) on the left, the macro label, and on the right
 *   "{value}g"             when pinned (custom value)
 *   "{value}g · auto"      when auto-balanced
 * followed by a lock icon — Filled.Lock (pink) when pinned, Outlined.LockOpen
 * (gray) when not.
 */
@Composable
private fun MacroSettingRow(
    label: String,
    value: Int,
    pinned: Boolean,
    onClick: () -> Unit
) {
    Row(
        Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .padding(horizontal = 16.dp, vertical = 14.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Icon(
            Icons.Outlined.DataUsage,
            contentDescription = null,
            tint = AppColors.Calorie,
            modifier = Modifier.size(22.dp)
        )
        Spacer(Modifier.width(14.dp))
        Text(label, modifier = Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge)
        Text(
            if (pinned) "${value}g" else "${value}g · auto",
            style = MaterialTheme.typography.bodyMedium,
            color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f)
        )
        Spacer(Modifier.width(8.dp))
        Icon(
            if (pinned) Icons.Filled.Lock else Icons.Outlined.LockOpen,
            contentDescription = if (pinned) "Pinned" else "Auto",
            tint = if (pinned) AppColors.Calorie
                   else MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f),
            modifier = Modifier.size(16.dp)
        )
    }
}

@Composable
private fun ToggleRow(
    label: String,
    checked: Boolean,
    icon: ImageVector? = null,
    onChange: (Boolean) -> Unit
) {
    Row(
        Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        if (icon != null) {
            Icon(
                icon,
                contentDescription = null,
                tint = AppColors.Calorie,
                modifier = Modifier.size(22.dp)
            )
            Spacer(Modifier.width(14.dp))
        }
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

private val birthdayFormatter: DateTimeFormatter =
    DateTimeFormatter.ofPattern("MMM d, yyyy", Locale.US)

private fun birthdayDisplay(profile: UserProfile): String {
    val date = profile.birthday.atZone(ZoneId.systemDefault()).toLocalDate()
    return "${date.format(birthdayFormatter)} (age ${profile.age})"
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun BirthdaySheet(current: Instant, onSave: (Instant) -> Unit) {
    // Material3 DatePicker stores selection as UTC-midnight millis. We store
    // birthdays as a local-zone Instant. Round-trip both sides through the
    // user's local date to avoid an off-by-one when the user is east of UTC.
    val localDate = current.atZone(ZoneId.systemDefault()).toLocalDate()
    val initialMillis = localDate.atStartOfDay(java.time.ZoneOffset.UTC)
        .toInstant().toEpochMilli()
    val state = rememberDatePickerState(initialSelectedDateMillis = initialMillis)
    Text("Birthday", style = MaterialTheme.typography.titleLarge, fontWeight = FontWeight.Bold)
    Spacer(Modifier.height(8.dp))
    DatePicker(
        state = state,
        title = null,
        headline = null,
        showModeToggle = false,
        colors = DatePickerDefaults.colors(
            selectedDayContainerColor = AppColors.Calorie,
            todayDateBorderColor = AppColors.Calorie,
            currentYearContentColor = AppColors.Calorie,
            selectedYearContainerColor = AppColors.Calorie
        )
    )
    Spacer(Modifier.height(12.dp))
    GradientSaveButton {
        val millis = state.selectedDateMillis ?: return@GradientSaveButton
        // Picker millis is UTC-midnight of the selected calendar day —
        // pull the LocalDate via UTC, then convert to local-zone Instant.
        val newDate = Instant.ofEpochMilli(millis)
            .atZone(java.time.ZoneOffset.UTC).toLocalDate()
        val newInstant = newDate.atStartOfDay(ZoneId.systemDefault()).toInstant()
        onSave(newInstant)
    }
    Spacer(Modifier.height(8.dp))
}

// Closest Material mappings for the iOS SF Symbols used in picker rows.
private fun genderIcon(g: Gender): ImageVector = when (g) {
    Gender.MALE -> Icons.Outlined.Male
    Gender.FEMALE -> Icons.Outlined.Female
    Gender.OTHER -> Icons.Outlined.Wc
}

private fun activityIcon(a: ActivityLevel): ImageVector = when (a) {
    ActivityLevel.SEDENTARY -> Icons.Outlined.SelfImprovement
    ActivityLevel.LIGHT -> Icons.AutoMirrored.Outlined.DirectionsWalk
    ActivityLevel.MODERATE -> Icons.AutoMirrored.Outlined.DirectionsRun
    ActivityLevel.ACTIVE -> Icons.Outlined.LocalDining
    ActivityLevel.VERY_ACTIVE -> Icons.Outlined.FitnessCenter
    ActivityLevel.EXTRA_ACTIVE -> Icons.Outlined.SportsMartialArts
}

private fun goalIcon(g: WeightGoal): ImageVector = when (g) {
    WeightGoal.LOSE -> Icons.AutoMirrored.Filled.TrendingDown
    WeightGoal.MAINTAIN -> Icons.AutoMirrored.Filled.TrendingFlat
    WeightGoal.GAIN -> Icons.AutoMirrored.Outlined.TrendingUp
}

private fun appearanceIcon(key: String): ImageVector = when (key) {
    "light" -> Icons.Outlined.LightMode
    "dark" -> Icons.Outlined.DarkMode
    else -> Icons.Outlined.SettingsBrightness
}

/**
 * Pink-gradient capsule "Save" button matching the iOS picker sheets
 * (`LinearGradient(colors: AppColors.calorieGradient)` over a 14dp rounded
 * rectangle, white semibold label).
 */
@Composable
private fun GradientSaveButton(
    text: String = "Save",
    enabled: Boolean = true,
    modifier: Modifier = Modifier,
    onClick: () -> Unit
) {
    val brush = Brush.linearGradient(listOf(AppColors.CalorieStart, AppColors.CalorieEnd))
    Box(
        modifier
            .fillMaxWidth()
            .clip(RoundedCornerShape(14.dp))
            .background(if (enabled) brush else Brush.linearGradient(listOf(AppColors.Calorie.copy(alpha = 0.4f), AppColors.Calorie.copy(alpha = 0.4f))))
            .clickable(enabled = enabled, onClick = onClick)
            .padding(vertical = 14.dp),
        contentAlignment = Alignment.Center
    ) {
        Text(text, color = Color.White, fontWeight = FontWeight.SemiBold, fontSize = 16.sp)
    }
}
