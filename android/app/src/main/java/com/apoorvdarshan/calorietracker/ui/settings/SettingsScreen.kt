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
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.HorizontalDivider
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
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
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.input.PasswordVisualTransformation
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import androidx.navigation.NavHostController
import com.apoorvdarshan.calorietracker.AppContainer
import com.apoorvdarshan.calorietracker.models.AIProvider
import com.apoorvdarshan.calorietracker.models.SpeechProvider

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun SettingsScreen(container: AppContainer, nav: NavHostController) {
    val vm: SettingsViewModel = viewModel(factory = SettingsViewModel.Factory(container))
    val ui by vm.ui.collectAsState()

    var showAISheet by remember { mutableStateOf(false) }
    var showModelSheet by remember { mutableStateOf(false) }
    var showSpeechSheet by remember { mutableStateOf(false) }
    var showKeySheet by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf(false) }

    Scaffold(topBar = { TopAppBar(title = { Text("Settings") }) }) { padding ->
        Column(
            Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState())
                .padding(16.dp),
            verticalArrangement = Arrangement.spacedBy(12.dp)
        ) {
            SectionCard(title = "AI Provider") {
                SettingRow(
                    label = "Provider",
                    value = ui.selectedAI.displayName,
                    onClick = { showAISheet = true }
                )
                HorizontalDivider()
                SettingRow(
                    label = "Model",
                    value = ui.selectedModel.ifEmpty { "(set one below)" },
                    onClick = { showModelSheet = true }
                )
                HorizontalDivider()
                SettingRow(
                    label = "API Key",
                    value = ui.apiKeyMasked.ifEmpty { "Not set" },
                    onClick = { showKeySheet = true }
                )
            }

            SectionCard(title = "Speech") {
                SettingRow(
                    label = "STT Engine",
                    value = ui.selectedSpeech.displayName,
                    onClick = { showSpeechSheet = true }
                )
            }

            SectionCard(title = "Units") {
                ToggleRow(
                    label = "Use metric (kg / cm)",
                    checked = ui.useMetric,
                    onChange = vm::setUseMetric
                )
            }

            SectionCard(title = "Notifications") {
                ToggleRow(
                    label = "Enable reminders",
                    checked = ui.notificationsEnabled,
                    onChange = vm::setNotificationsEnabled
                )
            }

            SectionCard(title = "Health Connect") {
                ToggleRow(
                    label = "Sync to Health Connect",
                    checked = ui.healthConnectEnabled,
                    onChange = vm::setHealthConnectEnabled
                )
            }

            SectionCard(title = "Danger zone") {
                TextButton(
                    onClick = { showDeleteDialog = true },
                    modifier = Modifier.fillMaxWidth().padding(vertical = 4.dp)
                ) {
                    Text("Delete all local data", color = Color(0xFFD32F2F))
                }
            }

            Spacer(Modifier.height(16.dp))
        }
    }

    if (showAISheet) {
        PickerSheet(onDismiss = { showAISheet = false }) {
            items(AIProvider.values().toList()) { p ->
                SheetRow(
                    label = p.displayName,
                    selected = p == ui.selectedAI
                ) {
                    vm.selectProvider(p)
                    showAISheet = false
                }
            }
        }
    }

    if (showModelSheet) {
        PickerSheet(onDismiss = { showModelSheet = false }) {
            items(ui.selectedAI.models) { m ->
                SheetRow(label = m, selected = m == ui.selectedModel) {
                    vm.selectModel(m)
                    showModelSheet = false
                }
            }
        }
    }

    if (showSpeechSheet) {
        PickerSheet(onDismiss = { showSpeechSheet = false }) {
            items(SpeechProvider.values().toList()) { p ->
                SheetRow(label = p.displayName, selected = p == ui.selectedSpeech) {
                    vm.selectSpeech(p)
                    showSpeechSheet = false
                }
            }
        }
    }

    if (showKeySheet) {
        var key by remember { mutableStateOf("") }
        ModalBottomSheet(onDismissRequest = { showKeySheet = false }) {
            Column(
                Modifier
                    .fillMaxWidth()
                    .padding(horizontal = 24.dp, vertical = 12.dp)
            ) {
                Text("API Key for ${ui.selectedAI.displayName}", style = MaterialTheme.typography.titleMedium)
                Text(ui.selectedAI.apiKeyPlaceholder, style = MaterialTheme.typography.bodySmall)
                Spacer(Modifier.height(12.dp))
                OutlinedTextField(
                    value = key,
                    onValueChange = { key = it },
                    placeholder = { Text(ui.selectedAI.apiKeyPlaceholder) },
                    visualTransformation = PasswordVisualTransformation(),
                    keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Password),
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(Modifier.height(12.dp))
                Button(
                    onClick = {
                        vm.setApiKey(key)
                        showKeySheet = false
                    },
                    modifier = Modifier.fillMaxWidth()
                ) { Text("Save") }
                Spacer(Modifier.height(8.dp))
                TextButton(
                    onClick = {
                        vm.setApiKey("")
                        showKeySheet = false
                    },
                    modifier = Modifier.fillMaxWidth()
                ) { Text("Clear") }
            }
        }
    }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Delete all local data?") },
            text = { Text("Wipes profile, food log, weight history, chat, API keys. Apple-equivalent Health data in Health Connect is untouched.") },
            confirmButton = {
                TextButton(onClick = {
                    vm.deleteAllData()
                    showDeleteDialog = false
                }) { Text("Delete", color = Color(0xFFD32F2F)) }
            },
            dismissButton = { TextButton(onClick = { showDeleteDialog = false }) { Text("Cancel") } }
        )
    }
}

@Composable
private fun SectionCard(title: String, content: @Composable () -> Unit) {
    Column {
        Text(
            title.uppercase(),
            style = MaterialTheme.typography.labelSmall,
            color = Color(0xFF8E8E93),
            modifier = Modifier.padding(start = 4.dp, bottom = 6.dp)
        )
        Card(
            shape = RoundedCornerShape(16.dp),
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
        Text(value, style = MaterialTheme.typography.bodyMedium, color = Color(0xFF8E8E93))
        Icon(Icons.Filled.ChevronRight, contentDescription = null, tint = Color(0xFF8E8E93))
    }
}

@Composable
private fun ToggleRow(label: String, checked: Boolean, onChange: (Boolean) -> Unit) {
    Row(
        Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        verticalAlignment = Alignment.CenterVertically
    ) {
        Text(label, modifier = Modifier.weight(1f), style = MaterialTheme.typography.bodyLarge)
        Switch(checked = checked, onCheckedChange = onChange)
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
private fun PickerSheet(onDismiss: () -> Unit, content: androidx.compose.foundation.lazy.LazyListScope.() -> Unit) {
    val state = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    ModalBottomSheet(onDismissRequest = onDismiss, sheetState = state) {
        LazyColumn(
            Modifier
                .fillMaxWidth()
                .padding(horizontal = 12.dp, vertical = 8.dp),
            verticalArrangement = Arrangement.spacedBy(2.dp),
            content = content
        )
    }
}

@Composable
private fun SheetRow(label: String, selected: Boolean, onClick: () -> Unit) {
    Box(
        Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick)
            .background(if (selected) MaterialTheme.colorScheme.primary.copy(alpha = 0.12f) else Color.Transparent)
            .padding(horizontal = 16.dp, vertical = 14.dp)
    ) {
        Text(label, style = MaterialTheme.typography.bodyLarge)
    }
}
