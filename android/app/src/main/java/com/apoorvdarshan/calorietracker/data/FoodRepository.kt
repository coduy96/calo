package com.apoorvdarshan.calorietracker.data

import com.apoorvdarshan.calorietracker.models.FoodEntry
import com.apoorvdarshan.calorietracker.models.MealType
import kotlinx.coroutines.flow.Flow
import kotlinx.coroutines.flow.first
import kotlinx.coroutines.flow.map
import java.time.Instant
import java.time.LocalDate
import java.time.ZoneId
import java.util.UUID

/**
 * CRUD + reactive reads for food entries. Port of iOS FoodStore.
 * Backed by [PreferencesStore] (entries + favorites serialized as JSON).
 */
class FoodRepository(private val prefs: PreferencesStore) {
    val entries: Flow<List<FoodEntry>> = prefs.foodEntries

    val favorites: Flow<List<FoodEntry>> = prefs.foodEntries.map { allEntries ->
        val favSet = prefs.favoriteKeys.first()
        allEntries.filter { it.favoriteKey in favSet }
    }

    val favoriteKeys: Flow<Set<String>> = prefs.favoriteKeys

    fun entriesForDate(date: LocalDate): Flow<List<FoodEntry>> = entries.map { list ->
        list.filter { it.timestamp.atZone(ZoneId.systemDefault()).toLocalDate() == date }
            .sortedByDescending { it.timestamp }
    }

    fun entriesByMealForDate(date: LocalDate): Flow<List<Pair<MealType, List<FoodEntry>>>> =
        entriesForDate(date).map { dayEntries ->
            MealType.values().mapNotNull { meal ->
                val mealEntries = dayEntries.filter { it.mealType == meal }
                if (mealEntries.isEmpty()) null else meal to mealEntries
            }
        }

    suspend fun addEntry(entry: FoodEntry) {
        val current = prefs.foodEntries.first()
        prefs.setFoodEntries(current + entry)
    }

    suspend fun updateEntry(entry: FoodEntry) {
        val current = prefs.foodEntries.first()
        val index = current.indexOfFirst { it.id == entry.id }
        if (index < 0) return
        val updated = current.toMutableList().also { it[index] = entry }
        prefs.setFoodEntries(updated)
    }

    suspend fun deleteEntry(entryId: UUID) {
        val current = prefs.foodEntries.first()
        prefs.setFoodEntries(current.filter { it.id != entryId })
    }

    suspend fun replaceAll(entries: List<FoodEntry>) {
        prefs.setFoodEntries(entries)
    }

    suspend fun clear() {
        prefs.setFoodEntries(emptyList())
    }

    // -- Favorites --------------------------------------------------------

    suspend fun isFavorite(entry: FoodEntry): Boolean {
        return entry.favoriteKey in prefs.favoriteKeys.first()
    }

    suspend fun toggleFavorite(entry: FoodEntry) {
        val current = prefs.favoriteKeys.first().toMutableSet()
        if (entry.favoriteKey in current) current.remove(entry.favoriteKey) else current.add(entry.favoriteKey)
        prefs.setFavoriteKeys(current)
    }

    // -- Recents / Frequent ---------------------------------------------

    suspend fun recent(limit: Int = 50): List<FoodEntry> =
        prefs.foodEntries.first().sortedByDescending { it.timestamp }.take(limit)

    suspend fun frequent(): List<FrequentFoodGroup> {
        val all = prefs.foodEntries.first()
        val aggregates = mutableMapOf<String, Pair<Int, FoodEntry>>()
        for (entry in all) {
            val key = entry.favoriteKey
            val existing = aggregates[key]
            if (existing != null) {
                val (count, template) = existing
                val newTemplate = if (entry.timestamp > template.timestamp) entry else template
                aggregates[key] = (count + 1) to newTemplate
            } else {
                aggregates[key] = 1 to entry
            }
        }
        return aggregates.map { (_, pair) ->
            FrequentFoodGroup(template = pair.second, count = pair.first)
        }.sortedWith(
            compareByDescending<FrequentFoodGroup> { it.count }.thenBy { it.name.lowercase() }
        )
    }
}

data class FrequentFoodGroup(
    val template: FoodEntry,
    val count: Int
) {
    val id: String = template.favoriteKey
    val name: String = template.name
    val calories: Int = template.calories
}

// Helper — converts Instant -> start-of-day in system zone.
@Suppress("unused")
internal fun Instant.toLocalDate(): LocalDate =
    this.atZone(ZoneId.systemDefault()).toLocalDate()
