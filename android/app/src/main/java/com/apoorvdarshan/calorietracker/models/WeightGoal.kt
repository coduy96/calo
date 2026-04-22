package com.apoorvdarshan.calorietracker.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
enum class WeightGoal {
    @SerialName("lose") LOSE,
    @SerialName("maintain") MAINTAIN,
    @SerialName("gain") GAIN;

    val displayName: String get() = when (this) {
        LOSE -> "Lose Weight"
        MAINTAIN -> "Maintain"
        GAIN -> "Gain Weight"
    }
}
