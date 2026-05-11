package com.apoorvdarshan.calorietracker.models

import kotlinx.serialization.Serializable
import kotlin.math.roundToInt

enum class HomeTopNutrient(
    val storageKey: String,
    val displayName: String,
    val unit: String
) {
    PROTEIN("protein", "Protein", "g"),
    CARBS("carbs", "Carbs", "g"),
    FAT("fat", "Fat", "g"),
    FIBER("fiber", "Fiber", "g"),
    SUGAR("sugar", "Sugar", "g"),
    ADDED_SUGAR("addedSugar", "Added Sugar", "g"),
    SATURATED_FAT("saturatedFat", "Sat Fat", "g"),
    CHOLESTEROL("cholesterol", "Cholesterol", "mg"),
    SODIUM("sodium", "Sodium", "mg"),
    POTASSIUM("potassium", "Potassium", "mg");

    fun current(entries: List<FoodEntry>): Int = when (this) {
        PROTEIN -> entries.sumOf { it.protein }
        CARBS -> entries.sumOf { it.carbs }
        FAT -> entries.sumOf { it.fat }
        FIBER -> entries.sumOf { it.fiber ?: 0.0 }.roundToInt()
        SUGAR -> entries.sumOf { it.sugar ?: 0.0 }.roundToInt()
        ADDED_SUGAR -> entries.sumOf { it.addedSugar ?: 0.0 }.roundToInt()
        SATURATED_FAT -> entries.sumOf { it.saturatedFat ?: 0.0 }.roundToInt()
        CHOLESTEROL -> entries.sumOf { it.cholesterol ?: 0.0 }.roundToInt()
        SODIUM -> entries.sumOf { it.sodium ?: 0.0 }.roundToInt()
        POTASSIUM -> entries.sumOf { it.potassium ?: 0.0 }.roundToInt()
    }

    fun goal(profile: UserProfile?, optionalGoals: OptionalNutrientGoals): Int = when (this) {
        PROTEIN -> profile?.effectiveProtein ?: 150
        CARBS -> profile?.effectiveCarbs ?: 220
        FAT -> profile?.effectiveFat ?: 70
        FIBER -> optionalGoals.fiber
        SUGAR -> optionalGoals.sugar
        ADDED_SUGAR -> optionalGoals.addedSugar
        SATURATED_FAT -> optionalGoals.saturatedFat
        CHOLESTEROL -> optionalGoals.cholesterol
        SODIUM -> optionalGoals.sodium
        POTASSIUM -> optionalGoals.potassium
    }

    companion object {
        val DefaultSelection = listOf(PROTEIN, CARBS, FAT)
        val DefaultStorageValue = DefaultSelection.joinToString(",") { it.storageKey }

        fun fromStorage(raw: String?): List<HomeTopNutrient> {
            val selected = raw
                ?.split(",")
                ?.mapNotNull { part ->
                    val key = part.trim()
                    values().firstOrNull { it.storageKey == key || it.name == key }
                }
                .orEmpty()
            return normalized(selected)
        }

        fun toStorage(selection: List<HomeTopNutrient>): String =
            normalized(selection).joinToString(",") { it.storageKey }

        fun normalized(selection: List<HomeTopNutrient>): List<HomeTopNutrient> =
            (selection.distinct() + DefaultSelection)
                .distinct()
                .take(3)
    }
}

enum class OptionalNutrient(
    val displayName: String,
    val unit: String,
    val defaultGoal: Int
) {
    SUGAR("Sugar", "g", 50),
    ADDED_SUGAR("Added Sugar", "g", 25),
    FIBER("Fiber", "g", 30),
    SATURATED_FAT("Saturated Fat", "g", 20),
    CHOLESTEROL("Cholesterol", "mg", 300),
    SODIUM("Sodium", "mg", 2300),
    POTASSIUM("Potassium", "mg", 3500)
}

@Serializable
data class OptionalNutrientGoals(
    val sugar: Int = OptionalNutrient.SUGAR.defaultGoal,
    val addedSugar: Int = OptionalNutrient.ADDED_SUGAR.defaultGoal,
    val fiber: Int = OptionalNutrient.FIBER.defaultGoal,
    val saturatedFat: Int = OptionalNutrient.SATURATED_FAT.defaultGoal,
    val cholesterol: Int = OptionalNutrient.CHOLESTEROL.defaultGoal,
    val sodium: Int = OptionalNutrient.SODIUM.defaultGoal,
    val potassium: Int = OptionalNutrient.POTASSIUM.defaultGoal
) {
    fun valueFor(nutrient: OptionalNutrient): Int = when (nutrient) {
        OptionalNutrient.SUGAR -> sugar
        OptionalNutrient.ADDED_SUGAR -> addedSugar
        OptionalNutrient.FIBER -> fiber
        OptionalNutrient.SATURATED_FAT -> saturatedFat
        OptionalNutrient.CHOLESTEROL -> cholesterol
        OptionalNutrient.SODIUM -> sodium
        OptionalNutrient.POTASSIUM -> potassium
    }

    fun withValue(nutrient: OptionalNutrient, value: Int): OptionalNutrientGoals {
        val safe = value.coerceAtLeast(0)
        return when (nutrient) {
            OptionalNutrient.SUGAR -> copy(sugar = safe)
            OptionalNutrient.ADDED_SUGAR -> copy(addedSugar = safe)
            OptionalNutrient.FIBER -> copy(fiber = safe)
            OptionalNutrient.SATURATED_FAT -> copy(saturatedFat = safe)
            OptionalNutrient.CHOLESTEROL -> copy(cholesterol = safe)
            OptionalNutrient.SODIUM -> copy(sodium = safe)
            OptionalNutrient.POTASSIUM -> copy(potassium = safe)
        }
    }

    companion object {
        val Default = OptionalNutrientGoals()
    }
}
