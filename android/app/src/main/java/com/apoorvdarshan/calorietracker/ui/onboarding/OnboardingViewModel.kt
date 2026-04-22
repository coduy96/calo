package com.apoorvdarshan.calorietracker.ui.onboarding

import androidx.lifecycle.ViewModel
import androidx.lifecycle.ViewModelProvider
import androidx.lifecycle.viewModelScope
import com.apoorvdarshan.calorietracker.AppContainer
import com.apoorvdarshan.calorietracker.models.ActivityLevel
import com.apoorvdarshan.calorietracker.models.Gender
import com.apoorvdarshan.calorietracker.models.UserProfile
import com.apoorvdarshan.calorietracker.models.WeightGoal
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId

enum class OnboardingStep {
    WELCOME, GENDER, BIRTHDAY, HEIGHT, WEIGHT, ACTIVITY, GOAL, GOAL_WEIGHT, PROVIDER, REVIEW
}

data class OnboardingState(
    val step: OnboardingStep = OnboardingStep.WELCOME,
    val gender: Gender = Gender.MALE,
    val birthday: LocalDate = LocalDate.now().minusYears(25),
    val heightCm: Int = 175,
    val weightKg: Double = 70.0,
    val activity: ActivityLevel = ActivityLevel.MODERATE,
    val goal: WeightGoal = WeightGoal.MAINTAIN,
    val goalWeightKg: Double = 70.0,
    val submitting: Boolean = false
) {
    val isLastStep: Boolean get() = step == OnboardingStep.REVIEW

    fun buildProfile(): UserProfile = UserProfile(
        gender = gender,
        birthday = birthday.atStartOfDay(ZoneId.systemDefault()).toInstant(),
        heightCm = heightCm.toDouble(),
        weightKg = weightKg,
        activityLevel = activity,
        goal = goal,
        goalWeightKg = if (goal == WeightGoal.MAINTAIN) null else goalWeightKg
    )
}

class OnboardingViewModel(private val container: AppContainer) : ViewModel() {
    private val _ui = MutableStateFlow(OnboardingState())
    val ui: StateFlow<OnboardingState> = _ui.asStateFlow()

    fun setGender(v: Gender) { _ui.value = _ui.value.copy(gender = v) }
    fun setBirthday(v: LocalDate) { _ui.value = _ui.value.copy(birthday = v) }
    fun setHeight(cm: Int) { _ui.value = _ui.value.copy(heightCm = cm) }
    fun setWeight(kg: Double) { _ui.value = _ui.value.copy(weightKg = kg, goalWeightKg = kg) }
    fun setActivity(v: ActivityLevel) { _ui.value = _ui.value.copy(activity = v) }
    fun setGoal(v: WeightGoal) {
        val defaultGoalWeight = when (v) {
            WeightGoal.LOSE -> _ui.value.weightKg - 5
            WeightGoal.GAIN -> _ui.value.weightKg + 5
            WeightGoal.MAINTAIN -> _ui.value.weightKg
        }
        _ui.value = _ui.value.copy(goal = v, goalWeightKg = defaultGoalWeight)
    }
    fun setGoalWeight(v: Double) { _ui.value = _ui.value.copy(goalWeightKg = v) }

    fun next() {
        val nextStep = OnboardingStep.values().getOrNull(_ui.value.step.ordinal + 1) ?: return
        _ui.value = _ui.value.copy(step = nextStep)
    }

    fun back() {
        val prev = OnboardingStep.values().getOrNull(_ui.value.step.ordinal - 1) ?: return
        _ui.value = _ui.value.copy(step = prev)
    }

    fun complete(onDone: () -> Unit) {
        viewModelScope.launch {
            _ui.value = _ui.value.copy(submitting = true)
            val profile = _ui.value.buildProfile()
            container.profileRepository.save(profile)
            container.weightRepository.seedInitialWeightIfEmpty(profile.weightKg)
            container.prefs.setOnboardingCompleted(true)
            onDone()
        }
    }

    class Factory(private val container: AppContainer) : ViewModelProvider.Factory {
        @Suppress("UNCHECKED_CAST")
        override fun <T : ViewModel> create(modelClass: Class<T>): T =
            OnboardingViewModel(container) as T
    }
}
