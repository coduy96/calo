package com.apoorvdarshan.calorietracker.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
enum class ActivityLevel {
    @SerialName("sedentary") SEDENTARY,
    @SerialName("light") LIGHT,
    @SerialName("moderate") MODERATE,
    @SerialName("active") ACTIVE,
    @SerialName("veryActive") VERY_ACTIVE,
    @SerialName("extraActive") EXTRA_ACTIVE;

    val displayName: String get() = when (this) {
        SEDENTARY -> "Sedentary"
        LIGHT -> "Light"
        MODERATE -> "Moderate"
        ACTIVE -> "Active"
        VERY_ACTIVE -> "Very Active"
        EXTRA_ACTIVE -> "Extra Active"
    }

    val subtitle: String get() = when (this) {
        SEDENTARY -> "Little or no exercise"
        LIGHT -> "Exercise 1–3 times / week"
        MODERATE -> "Exercise 4–5 times / week"
        ACTIVE -> "Daily exercise or intense 3–4x / week"
        VERY_ACTIVE -> "Intense exercise 6–7 times / week"
        EXTRA_ACTIVE -> "Very intense daily, or physical job"
    }

    val multiplier: Double get() = when (this) {
        SEDENTARY -> 1.2
        LIGHT -> 1.375
        MODERATE -> 1.465
        ACTIVE -> 1.55
        VERY_ACTIVE -> 1.725
        EXTRA_ACTIVE -> 1.9
    }

    /** g protein per kg bodyweight per activity level (ISSN 2017 / Morton et al 2018 aligned). */
    val proteinPerKg: Double get() = when (this) {
        SEDENTARY -> 0.8
        LIGHT -> 1.2
        MODERATE -> 1.6
        ACTIVE -> 1.8
        VERY_ACTIVE -> 2.0
        EXTRA_ACTIVE -> 2.2
    }
}
