package com.apoorvdarshan.calorietracker.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable
import java.time.LocalTime

@Serializable
enum class MealType {
    @SerialName("breakfast") BREAKFAST,
    @SerialName("lunch") LUNCH,
    @SerialName("dinner") DINNER,
    @SerialName("snack") SNACK,
    @SerialName("other") OTHER;

    val displayName: String get() = when (this) {
        BREAKFAST -> "Breakfast"
        LUNCH -> "Lunch"
        DINNER -> "Dinner"
        SNACK -> "Snack"
        OTHER -> "Other"
    }

    companion object {
        val currentMeal: MealType get() {
            val hour = LocalTime.now().hour
            return when (hour) {
                in 5..10 -> BREAKFAST
                in 11..14 -> LUNCH
                in 15..20 -> DINNER
                else -> SNACK
            }
        }
    }
}
