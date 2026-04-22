package com.apoorvdarshan.calorietracker.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
enum class SpeechProvider {
    @SerialName("Native (On-Device)") NATIVE,
    @SerialName("OpenAI Whisper") OPENAI,
    @SerialName("Groq (Whisper)") GROQ,
    @SerialName("Deepgram") DEEPGRAM,
    @SerialName("AssemblyAI") ASSEMBLY_AI;

    val displayName: String get() = when (this) {
        NATIVE -> "Native (On-Device)"
        OPENAI -> "OpenAI Whisper"
        GROQ -> "Groq (Whisper)"
        DEEPGRAM -> "Deepgram"
        ASSEMBLY_AI -> "AssemblyAI"
    }

    val requiresApiKey: Boolean get() = this != NATIVE

    val apiKeyPlaceholder: String get() = when (this) {
        NATIVE -> "Not needed"
        OPENAI -> "sk-..."
        GROQ -> "gsk_..."
        DEEPGRAM -> "Token your-deepgram-key"
        ASSEMBLY_AI -> "Your AssemblyAI key"
    }

    val defaultModel: String get() = when (this) {
        NATIVE -> ""
        OPENAI -> "whisper-1"
        GROQ -> "whisper-large-v3"
        DEEPGRAM -> "nova-3"
        ASSEMBLY_AI -> "universal"
    }

    val description: String get() = when (this) {
        NATIVE -> "Android's on-device speech recognition. Free, works offline on most phones, real-time partial results. Recommended default."
        OPENAI -> "OpenAI Whisper API. High accuracy, 99+ languages, paid per minute."
        GROQ -> "Groq-hosted Whisper Large v3. Very fast inference, has a free tier."
        DEEPGRAM -> "Deepgram Nova. Real-time and batch modes, fast and accurate."
        ASSEMBLY_AI -> "AssemblyAI Universal model. Strong accuracy, free tier available."
    }
}
