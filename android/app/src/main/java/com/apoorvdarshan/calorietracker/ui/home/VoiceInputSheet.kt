package com.apoorvdarshan.calorietracker.ui.home

import android.Manifest
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.animation.core.animateFloatAsState
import androidx.compose.animation.core.tween
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.interaction.MutableInteractionSource
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Mic
import androidx.compose.material.icons.filled.Stop
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.runtime.Composable
import androidx.compose.runtime.DisposableEffect
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import com.apoorvdarshan.calorietracker.AppContainer
import com.apoorvdarshan.calorietracker.models.SpeechProvider
import com.apoorvdarshan.calorietracker.services.speech.AudioRecorder
import com.apoorvdarshan.calorietracker.services.speech.NativeSpeechRecognizer
import com.apoorvdarshan.calorietracker.services.speech.SttEvent
import com.apoorvdarshan.calorietracker.ui.theme.AppColors
import kotlinx.coroutines.Job
import kotlinx.coroutines.flow.collectLatest
import kotlinx.coroutines.launch
import java.io.File

private enum class VoicePhase { IDLE, RECORDING, REVIEWING, TRANSCRIBING }

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun VoiceInputSheet(
    container: AppContainer,
    onDismiss: () -> Unit,
    onSubmit: (String) -> Unit
) {
    val ctx = LocalContext.current
    val sheetState = rememberModalBottomSheetState(skipPartiallyExpanded = true)
    val scope = rememberCoroutineScope()

    val provider by container.prefs.selectedSpeechProvider.collectAsState(initial = SpeechProvider.NATIVE)

    var phase by remember { mutableStateOf(VoicePhase.IDLE) }
    var transcript by remember { mutableStateOf("") }
    var error by remember { mutableStateOf<String?>(null) }
    val recorder = remember(ctx) { AudioRecorder(ctx) }
    val native = remember(ctx) { NativeSpeechRecognizer(ctx) }
    var recordedFile by remember { mutableStateOf<File?>(null) }
    var nativeJob by remember { mutableStateOf<Job?>(null) }

    val micPermission = rememberLauncherForActivityResult(
        ActivityResultContracts.RequestPermission()
    ) { granted ->
        if (!granted) error = "Microphone permission denied."
    }

    LaunchedEffect(Unit) {
        if (!native.hasMicPermission()) micPermission.launch(Manifest.permission.RECORD_AUDIO)
    }

    DisposableEffect(Unit) {
        onDispose {
            nativeJob?.cancel()
            recorder.cancel()
        }
    }

    ModalBottomSheet(
        onDismissRequest = {
            nativeJob?.cancel()
            recorder.cancel()
            onDismiss()
        },
        sheetState = sheetState,
        shape = RoundedCornerShape(topStart = 28.dp, topEnd = 28.dp),
        containerColor = MaterialTheme.colorScheme.surface
    ) {
        Column(
            Modifier
                .fillMaxWidth()
                .padding(24.dp)
        ) {
            Text(
                "Voice log",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            Text(
                "Using ${provider.displayName}",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.55f)
            )
            Spacer(Modifier.height(20.dp))

            Box(
                Modifier
                    .fillMaxWidth()
                    .height(180.dp),
                contentAlignment = Alignment.Center
            ) {
                MicButton(
                    phase = phase,
                    onToggle = {
                        when (phase) {
                            VoicePhase.IDLE -> {
                                transcript = ""
                                error = null
                                if (provider == SpeechProvider.NATIVE) {
                                    phase = VoicePhase.RECORDING
                                    nativeJob?.cancel()
                                    nativeJob = scope.launch {
                                        native.listen().collectLatest { event ->
                                            when (event) {
                                                is SttEvent.Partial -> transcript = event.text
                                                is SttEvent.Final -> {
                                                    transcript = event.text
                                                    phase = VoicePhase.REVIEWING
                                                }
                                                is SttEvent.Error -> {
                                                    error = event.message
                                                    phase = VoicePhase.IDLE
                                                }
                                                else -> Unit
                                            }
                                        }
                                    }
                                } else {
                                    val file = recorder.start()
                                    if (file == null) {
                                        error = "Couldn't start the mic. Check permissions."
                                    } else {
                                        recordedFile = file
                                        phase = VoicePhase.RECORDING
                                    }
                                }
                            }
                            VoicePhase.RECORDING -> {
                                if (provider == SpeechProvider.NATIVE) {
                                    nativeJob?.cancel()
                                    phase = VoicePhase.REVIEWING
                                } else {
                                    val file = recorder.stop()
                                    if (file != null) {
                                        phase = VoicePhase.TRANSCRIBING
                                        scope.launch {
                                            try {
                                                transcript = container.speechService.transcribeRemote(file)
                                                phase = VoicePhase.REVIEWING
                                            } catch (e: Throwable) {
                                                error = e.localizedMessage ?: "Transcription failed"
                                                phase = VoicePhase.IDLE
                                            }
                                        }
                                    } else {
                                        phase = VoicePhase.IDLE
                                    }
                                }
                            }
                            else -> Unit
                        }
                    }
                )
            }

            Spacer(Modifier.height(12.dp))

            Text(
                when (phase) {
                    VoicePhase.IDLE -> "Tap to start recording"
                    VoicePhase.RECORDING -> "Listening… tap to stop"
                    VoicePhase.TRANSCRIBING -> "Transcribing…"
                    VoicePhase.REVIEWING -> "Review your transcript"
                },
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurface.copy(alpha = 0.6f),
                modifier = Modifier.fillMaxWidth(),
                textAlign = androidx.compose.ui.text.style.TextAlign.Center
            )

            if (transcript.isNotEmpty() || phase == VoicePhase.REVIEWING) {
                Spacer(Modifier.height(20.dp))
                OutlinedTextField(
                    value = transcript,
                    onValueChange = { transcript = it },
                    placeholder = { Text("Your transcription will appear here") },
                    modifier = Modifier.fillMaxWidth()
                )
                Spacer(Modifier.height(14.dp))
                Button(
                    onClick = {
                        if (transcript.isNotBlank()) {
                            onSubmit(transcript.trim())
                        }
                    },
                    enabled = transcript.isNotBlank(),
                    colors = ButtonDefaults.buttonColors(containerColor = AppColors.Calorie),
                    shape = RoundedCornerShape(20.dp),
                    modifier = Modifier.fillMaxWidth().height(52.dp)
                ) {
                    Text("Analyze", color = Color.White, fontWeight = FontWeight.SemiBold)
                }
            }

            error?.let {
                Spacer(Modifier.height(10.dp))
                Text(it, color = MaterialTheme.colorScheme.error, style = MaterialTheme.typography.bodySmall)
            }

            Spacer(Modifier.height(8.dp))
            TextButton(onClick = {
                nativeJob?.cancel()
                recorder.cancel()
                onDismiss()
            }, modifier = Modifier.fillMaxWidth()) {
                Text("Cancel")
            }
        }
    }
}

@Composable
private fun MicButton(phase: VoicePhase, onToggle: () -> Unit) {
    val recording = phase == VoicePhase.RECORDING
    val scale by animateFloatAsState(
        targetValue = if (recording) 1.12f else 1f,
        animationSpec = tween(250),
        label = "micScale"
    )
    val interactionSource = remember { MutableInteractionSource() }
    Box(
        Modifier
            .size((110 * scale).dp)
            .clip(CircleShape)
            .background(Brush.linearGradient(listOf(AppColors.CalorieStart, AppColors.CalorieEnd)))
            .clickable(
                interactionSource = interactionSource,
                indication = null,
                onClick = onToggle
            ),
        contentAlignment = Alignment.Center
    ) {
        Icon(
            imageVector = if (recording) Icons.Filled.Stop else Icons.Filled.Mic,
            contentDescription = if (recording) "Stop" else "Record",
            tint = Color.White,
            modifier = Modifier.size(44.dp)
        )
    }
}
