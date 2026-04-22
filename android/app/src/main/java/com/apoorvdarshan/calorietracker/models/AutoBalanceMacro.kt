package com.apoorvdarshan.calorietracker.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
enum class AutoBalanceMacro {
    @SerialName("protein") PROTEIN,
    @SerialName("carbs") CARBS,
    @SerialName("fat") FAT;

    val label: String get() = when (this) {
        PROTEIN -> "Protein"
        CARBS -> "Carbs"
        FAT -> "Fat"
    }

    val kcalPerGram: Int get() = if (this == FAT) 9 else 4
}
