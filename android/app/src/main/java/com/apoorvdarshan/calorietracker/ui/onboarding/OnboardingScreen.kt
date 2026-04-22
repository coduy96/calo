package com.apoorvdarshan.calorietracker.ui.onboarding

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
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.LinearProgressIndicator
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.lifecycle.viewmodel.compose.viewModel
import com.apoorvdarshan.calorietracker.AppContainer
import com.apoorvdarshan.calorietracker.models.ActivityLevel
import com.apoorvdarshan.calorietracker.models.Gender
import com.apoorvdarshan.calorietracker.models.WeightGoal
import com.apoorvdarshan.calorietracker.ui.theme.AppColors
import java.time.LocalDate
import java.time.Period
import java.util.Locale

@Composable
fun OnboardingScreen(container: AppContainer, onComplete: () -> Unit) {
    val vm: OnboardingViewModel = viewModel(factory = OnboardingViewModel.Factory(container))
    val ui by vm.ui.collectAsState()

    Column(
        Modifier
            .fillMaxSize()
            .background(MaterialTheme.colorScheme.background)
            .padding(24.dp)
    ) {
        val progress = (ui.step.ordinal + 1).toFloat() / OnboardingStep.values().size.toFloat()
        LinearProgressIndicator(
            progress = { progress },
            color = AppColors.Calorie,
            modifier = Modifier
                .fillMaxWidth()
                .height(4.dp)
                .clip(RoundedCornerShape(2.dp))
        )
        Spacer(Modifier.height(24.dp))

        Box(Modifier.weight(1f).fillMaxWidth()) {
            when (ui.step) {
                OnboardingStep.WELCOME -> WelcomeStep()
                OnboardingStep.GENDER -> GenderStep(selected = ui.gender, onSelect = vm::setGender)
                OnboardingStep.BIRTHDAY -> BirthdayStep(current = ui.birthday, onChange = vm::setBirthday)
                OnboardingStep.HEIGHT -> HeightStep(cm = ui.heightCm, onChange = vm::setHeight)
                OnboardingStep.WEIGHT -> WeightStep(kg = ui.weightKg, onChange = vm::setWeight)
                OnboardingStep.ACTIVITY -> ActivityStep(selected = ui.activity, onSelect = vm::setActivity)
                OnboardingStep.GOAL -> GoalStep(selected = ui.goal, onSelect = vm::setGoal)
                OnboardingStep.GOAL_WEIGHT -> GoalWeightStep(current = ui.goalWeightKg, goal = ui.goal, onChange = vm::setGoalWeight)
                OnboardingStep.PROVIDER -> ProviderStep()
                OnboardingStep.REVIEW -> ReviewStep(state = ui)
            }
        }

        Row(Modifier.fillMaxWidth()) {
            if (ui.step != OnboardingStep.WELCOME) {
                TextButton(onClick = { vm.back() }) { Text("Back") }
            }
            Spacer(Modifier.weight(1f))
            Button(
                onClick = { if (ui.isLastStep) vm.complete(onComplete) else vm.next() },
                colors = androidx.compose.material3.ButtonDefaults.buttonColors(containerColor = AppColors.Calorie)
            ) {
                Text(if (ui.isLastStep) "Finish" else "Next", color = Color.White)
            }
        }
    }
}

@Composable
private fun WelcomeStep() {
    Column(Modifier.fillMaxSize(), verticalArrangement = Arrangement.Center, horizontalAlignment = Alignment.CenterHorizontally) {
        Text("Fud AI", style = MaterialTheme.typography.displayMedium, fontWeight = FontWeight.Bold)
        Spacer(Modifier.height(16.dp))
        Text(
            "Snap a photo, speak, or type. AI handles the rest.\nFree, open source, bring your own API key.",
            style = MaterialTheme.typography.bodyLarge,
            color = Color(0xFF8E8E93)
        )
    }
}

@Composable
private fun GenderStep(selected: Gender, onSelect: (Gender) -> Unit) {
    StepColumn(title = "How do you identify?") {
        for (g in Gender.values()) {
            ChoiceRow(label = g.displayName, selected = g == selected) { onSelect(g) }
        }
    }
}

@Composable
private fun BirthdayStep(current: LocalDate, onChange: (LocalDate) -> Unit) {
    var input by remember { mutableStateOf(current.toString()) }
    StepColumn(title = "Your birthday?") {
        Text(
            "YYYY-MM-DD",
            color = Color(0xFF8E8E93),
            style = MaterialTheme.typography.bodySmall
        )
        OutlinedTextField(
            value = input,
            onValueChange = {
                input = it
                runCatching { LocalDate.parse(it) }.getOrNull()?.let(onChange)
            },
            modifier = Modifier.fillMaxWidth()
        )
        val age = Period.between(current, LocalDate.now()).years
        Text("Age: $age", color = Color(0xFF8E8E93), style = MaterialTheme.typography.bodySmall)
    }
}

@Composable
private fun HeightStep(cm: Int, onChange: (Int) -> Unit) {
    var input by remember { mutableStateOf(cm.toString()) }
    StepColumn(title = "Your height (cm)?") {
        OutlinedTextField(
            value = input,
            onValueChange = {
                input = it
                it.toIntOrNull()?.let(onChange)
            },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
            modifier = Modifier.fillMaxWidth()
        )
    }
}

@Composable
private fun WeightStep(kg: Double, onChange: (Double) -> Unit) {
    var input by remember { mutableStateOf(String.format(Locale.US, "%.1f", kg)) }
    StepColumn(title = "Your current weight (kg)?") {
        OutlinedTextField(
            value = input,
            onValueChange = {
                input = it
                it.toDoubleOrNull()?.let(onChange)
            },
            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
            modifier = Modifier.fillMaxWidth()
        )
    }
}

@Composable
private fun ActivityStep(selected: ActivityLevel, onSelect: (ActivityLevel) -> Unit) {
    StepColumn(title = "How active are you?") {
        for (a in ActivityLevel.values()) {
            ChoiceRow(
                label = a.displayName,
                subtitle = a.subtitle,
                selected = a == selected
            ) { onSelect(a) }
        }
    }
}

@Composable
private fun GoalStep(selected: WeightGoal, onSelect: (WeightGoal) -> Unit) {
    StepColumn(title = "What's your goal?") {
        for (g in WeightGoal.values()) {
            ChoiceRow(label = g.displayName, selected = g == selected) { onSelect(g) }
        }
    }
}

@Composable
private fun GoalWeightStep(current: Double, goal: WeightGoal, onChange: (Double) -> Unit) {
    var input by remember { mutableStateOf(String.format(Locale.US, "%.1f", current)) }
    StepColumn(title = "Your target weight (kg)?") {
        if (goal == WeightGoal.MAINTAIN) {
            Text("Skip — maintaining current weight.", color = Color(0xFF8E8E93))
        } else {
            OutlinedTextField(
                value = input,
                onValueChange = {
                    input = it
                    it.toDoubleOrNull()?.let(onChange)
                },
                keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal),
                modifier = Modifier.fillMaxWidth()
            )
        }
    }
}

@Composable
private fun ProviderStep() {
    StepColumn(title = "AI Provider") {
        Text(
            "Fud AI uses your own API key — no subscription, nothing transmitted through us.\n\nThe default is Google Gemini (free tier). You can pick a different one in Settings after onboarding, and paste your key there.",
            color = Color(0xFF8E8E93)
        )
    }
}

@Composable
private fun ReviewStep(state: OnboardingState) {
    StepColumn(title = "Review") {
        Text("Gender: ${state.gender.displayName}")
        Text("Age: ${Period.between(state.birthday, LocalDate.now()).years}")
        Text("Height: ${state.heightCm} cm")
        Text("Weight: ${String.format(Locale.US, "%.1f", state.weightKg)} kg")
        Text("Activity: ${state.activity.displayName}")
        Text("Goal: ${state.goal.displayName}")
        if (state.goal != WeightGoal.MAINTAIN) {
            Text("Target: ${String.format(Locale.US, "%.1f", state.goalWeightKg)} kg")
        }
    }
}

@Composable
private fun StepColumn(title: String, content: @Composable () -> Unit) {
    Column(verticalArrangement = Arrangement.spacedBy(12.dp)) {
        Text(title, style = MaterialTheme.typography.headlineSmall, fontWeight = FontWeight.SemiBold)
        content()
    }
}

@Composable
private fun ChoiceRow(label: String, subtitle: String? = null, selected: Boolean, onClick: () -> Unit) {
    Card(
        shape = RoundedCornerShape(14.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (selected) AppColors.Calorie.copy(alpha = 0.15f) else MaterialTheme.colorScheme.surface
        ),
        modifier = Modifier.fillMaxWidth().clickable(onClick = onClick)
    ) {
        Row(
            Modifier.fillMaxWidth().padding(horizontal = 16.dp, vertical = 14.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Box(
                Modifier
                    .size(20.dp)
                    .clip(CircleShape)
                    .background(if (selected) AppColors.Calorie else Color.Transparent)
                    .padding(2.dp)
            )
            Spacer(Modifier.size(12.dp))
            Column(Modifier.weight(1f)) {
                Text(label, style = MaterialTheme.typography.bodyLarge)
                subtitle?.let {
                    Text(it, style = MaterialTheme.typography.bodySmall, color = Color(0xFF8E8E93))
                }
            }
        }
    }
}
