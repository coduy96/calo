package com.apoorvdarshan.calorietracker.models

import kotlinx.serialization.SerialName
import kotlinx.serialization.Serializable

@Serializable
enum class Gender {
    @SerialName("male") MALE,
    @SerialName("female") FEMALE,
    @SerialName("other") OTHER;

    val displayName: String get() = when (this) {
        MALE -> "Male"
        FEMALE -> "Female"
        OTHER -> "Other"
    }
}
