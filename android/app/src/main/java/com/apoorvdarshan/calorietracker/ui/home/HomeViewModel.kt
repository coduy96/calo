package com.apoorvdarshan.calorietracker.ui.home

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.apoorvdarshan.calorietracker.AppContainer
import com.apoorvdarshan.calorietracker.models.FoodEntry
import com.apoorvdarshan.calorietracker.models.FoodSource
import com.apoorvdarshan.calorietracker.models.MealType
import com.apoorvdarshan.calorietracker.models.UserProfile
import com.apoorvdarshan.calorietracker.services.ai.AiError
import com.apoorvdarshan.calorietracker.services.ai.FoodAnalysis
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.combine
import kotlinx.coroutines.flow.launchIn
import kotlinx.coroutines.flow.onEach
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.util.UUID

data class HomeUiState(
    val date: LocalDate = LocalDate.now(),
    val profile: UserProfile? = null,
    val todayEntries: List<FoodEntry> = emptyList(),
    val pendingAnalysis: FoodAnalysis? = null,
    val pendingImageBytes: ByteArray? = null,
    val analyzing: Boolean = false,
    val error: String? = null
) {
    val caloriesToday: Int get() = todayEntries.sumOf { it.calories }
    val proteinToday: Int get() = todayEntries.sumOf { it.protein }
    val carbsToday: Int get() = todayEntries.sumOf { it.carbs }
    val fatToday: Int get() = todayEntries.sumOf { it.fat }
}

class HomeViewModel(private val container: AppContainer) : ViewModel() {
    private val _ui = MutableStateFlow(HomeUiState())
    val ui: StateFlow<HomeUiState> = _ui.asStateFlow()

    init {
        combine(container.profileRepository.profile, container.foodRepository.entries) { p, entries ->
            val today = LocalDate.now()
            val zone = ZoneId.systemDefault()
            val todayEntries = entries
                .filter { it.timestamp.atZone(zone).toLocalDate() == today }
                .sortedByDescending { it.timestamp }
            _ui.value.copy(profile = p, todayEntries = todayEntries)
        }
            .onEach { _ui.value = it }
            .launchIn(viewModelScope)
    }

    fun analyzeText(description: String) {
        viewModelScope.launch {
            _ui.value = _ui.value.copy(analyzing = true, error = null, pendingAnalysis = null, pendingImageBytes = null)
            try {
                val analysis = container.foodAnalysis.analyzeText(description)
                _ui.value = _ui.value.copy(analyzing = false, pendingAnalysis = analysis)
            } catch (e: AiError) {
                _ui.value = _ui.value.copy(analyzing = false, error = e.message)
            } catch (e: Throwable) {
                _ui.value = _ui.value.copy(analyzing = false, error = e.localizedMessage ?: "Analysis failed")
            }
        }
    }

    fun analyzePhoto(bytes: ByteArray) {
        viewModelScope.launch {
            _ui.value = _ui.value.copy(analyzing = true, error = null, pendingAnalysis = null, pendingImageBytes = bytes)
            try {
                val analysis = container.foodAnalysis.analyzeAuto(bytes)
                _ui.value = _ui.value.copy(analyzing = false, pendingAnalysis = analysis)
            } catch (e: AiError) {
                _ui.value = _ui.value.copy(analyzing = false, error = e.message)
            } catch (e: Throwable) {
                _ui.value = _ui.value.copy(analyzing = false, error = e.localizedMessage ?: "Analysis failed")
            }
        }
    }

    fun saveAnalysis(
        name: String? = null,
        servingGrams: Double? = null,
        scale: Double = 1.0,
        mealType: MealType = MealType.currentMeal
    ) {
        val analysis = _ui.value.pendingAnalysis ?: return
        viewModelScope.launch {
            val imageBytes = _ui.value.pendingImageBytes
            val id = UUID.randomUUID()
            val filename = imageBytes?.let { container.imageStore.storeBytes(it, id) }
            fun s(v: Int) = (v * scale).toInt()
            fun s(v: Double?) = v?.let { it * scale }
            val entry = FoodEntry(
                id = id,
                name = name?.takeIf { it.isNotBlank() } ?: analysis.name,
                calories = s(analysis.calories),
                protein = s(analysis.protein),
                carbs = s(analysis.carbs),
                fat = s(analysis.fat),
                timestamp = Instant.now(),
                imageFilename = filename,
                emoji = analysis.emoji,
                source = if (imageBytes != null) FoodSource.SNAP_FOOD else FoodSource.TEXT_INPUT,
                mealType = mealType,
                sugar = s(analysis.sugar),
                fiber = s(analysis.fiber),
                saturatedFat = s(analysis.saturatedFat),
                monounsaturatedFat = s(analysis.monounsaturatedFat),
                polyunsaturatedFat = s(analysis.polyunsaturatedFat),
                cholesterol = s(analysis.cholesterol),
                sodium = s(analysis.sodium),
                potassium = s(analysis.potassium),
                servingSizeGrams = servingGrams ?: analysis.servingSizeGrams
            )
            container.foodRepository.addEntry(entry)
            _ui.value = _ui.value.copy(pendingAnalysis = null, pendingImageBytes = null)
        }
    }

    fun dismissPending() {
        _ui.value = _ui.value.copy(pendingAnalysis = null, pendingImageBytes = null, error = null)
    }

    fun deleteEntry(id: UUID) {
        viewModelScope.launch {
            container.foodRepository.deleteEntry(id)
        }
    }

    fun updateEntry(entry: FoodEntry) {
        viewModelScope.launch {
            container.foodRepository.updateEntry(entry)
        }
    }

    /** Re-log a saved meal (from Saved Meals sheet) as a new entry timestamped now. */
    fun relogMeal(template: FoodEntry) {
        viewModelScope.launch {
            container.foodRepository.addEntry(template.duplicatedForLogging(Instant.now()))
        }
    }

    class Factory(private val container: AppContainer) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T =
            HomeViewModel(container) as T
    }
}
