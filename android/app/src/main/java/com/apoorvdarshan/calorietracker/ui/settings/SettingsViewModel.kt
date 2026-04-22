package com.apoorvdarshan.calorietracker.ui.settings

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.apoorvdarshan.calorietracker.AppContainer
import com.apoorvdarshan.calorietracker.models.AIProvider
import com.apoorvdarshan.calorietracker.models.SpeechProvider
import com.apoorvdarshan.calorietracker.models.UserProfile
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch

data class SettingsUiState(
    val selectedAI: AIProvider = AIProvider.GEMINI,
    val selectedModel: String = AIProvider.GEMINI.defaultModel,
    val selectedSpeech: SpeechProvider = SpeechProvider.NATIVE,
    val useMetric: Boolean = true,
    val profile: UserProfile? = null,
    val notificationsEnabled: Boolean = false,
    val healthConnectEnabled: Boolean = false,
    val apiKeyMasked: String = ""
)

class SettingsViewModel(private val container: AppContainer) : ViewModel() {
    private val _ui = MutableStateFlow(SettingsUiState())
    val ui: StateFlow<SettingsUiState> = _ui.asStateFlow()

    init {
        viewModelScope.launch {
            val provider = container.prefs.selectedAIProvider.first()
            val model = container.prefs.selectedAIModel.first() ?: provider.defaultModel
            val speech = container.prefs.selectedSpeechProvider.first()
            val useMetric = container.prefs.useMetric.first()
            val profile = container.profileRepository.current()
            val notif = container.prefs.notificationsEnabled.first()
            val hc = container.prefs.healthConnectEnabled.first()
            val masked = maskKey(container.keyStore.apiKey(provider))
            _ui.value = SettingsUiState(
                selectedAI = provider,
                selectedModel = model,
                selectedSpeech = speech,
                useMetric = useMetric,
                profile = profile,
                notificationsEnabled = notif,
                healthConnectEnabled = hc,
                apiKeyMasked = masked
            )
        }
    }

    fun selectProvider(p: AIProvider) {
        viewModelScope.launch {
            container.prefs.setSelectedAIProvider(p)
            container.prefs.setSelectedAIModel(p.defaultModel)
            val masked = maskKey(container.keyStore.apiKey(p))
            _ui.value = _ui.value.copy(selectedAI = p, selectedModel = p.defaultModel, apiKeyMasked = masked)
        }
    }

    fun selectModel(m: String) {
        viewModelScope.launch {
            container.prefs.setSelectedAIModel(m)
            _ui.value = _ui.value.copy(selectedModel = m)
        }
    }

    fun setApiKey(raw: String) {
        viewModelScope.launch {
            val p = _ui.value.selectedAI
            container.keyStore.setApiKey(p, raw.takeIf { it.isNotBlank() })
            _ui.value = _ui.value.copy(apiKeyMasked = maskKey(raw.takeIf { it.isNotBlank() }))
        }
    }

    fun selectSpeech(p: SpeechProvider) {
        viewModelScope.launch {
            container.prefs.setSelectedSpeechProvider(p)
            _ui.value = _ui.value.copy(selectedSpeech = p)
        }
    }

    fun setUseMetric(v: Boolean) {
        viewModelScope.launch {
            container.prefs.setUseMetric(v)
            _ui.value = _ui.value.copy(useMetric = v)
        }
    }

    fun setNotificationsEnabled(v: Boolean) {
        viewModelScope.launch {
            container.prefs.setNotificationsEnabled(v)
            _ui.value = _ui.value.copy(notificationsEnabled = v)
        }
    }

    fun setHealthConnectEnabled(v: Boolean) {
        viewModelScope.launch {
            container.prefs.setHealthConnectEnabled(v)
            _ui.value = _ui.value.copy(healthConnectEnabled = v)
        }
    }

    fun deleteAllData() {
        viewModelScope.launch {
            container.prefs.clearAll()
            container.keyStore.clearAll()
            container.imageStore.clearAll()
        }
    }

    private fun maskKey(key: String?): String =
        if (key.isNullOrBlank()) "" else key.take(4) + "..." + key.takeLast(4)

    class Factory(private val container: AppContainer) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T =
            SettingsViewModel(container) as T
    }
}
