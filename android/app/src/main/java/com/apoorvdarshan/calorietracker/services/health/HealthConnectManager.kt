package com.apoorvdarshan.calorietracker.services.health

import android.content.Context
import androidx.health.connect.client.HealthConnectClient
import androidx.health.connect.client.PermissionController
import androidx.health.connect.client.changes.DeletionChange
import androidx.health.connect.client.changes.UpsertionChange
import androidx.health.connect.client.permission.HealthPermission
import androidx.health.connect.client.records.MealType as HCMealType
import androidx.health.connect.client.records.NutritionRecord
import androidx.health.connect.client.records.WeightRecord
import androidx.health.connect.client.records.metadata.Metadata
import androidx.health.connect.client.request.ReadRecordsRequest
import androidx.health.connect.client.time.TimeRangeFilter
import androidx.health.connect.client.units.Energy
import androidx.health.connect.client.units.Mass
import com.apoorvdarshan.calorietracker.models.FoodEntry
import com.apoorvdarshan.calorietracker.models.WeightEntry
import java.time.Instant
import java.time.ZoneOffset
import java.util.UUID

/**
 * Single boundary for Health Connect I/O. Port of iOS HealthKitManager.
 *
 * Conventions:
 * - Each sample carries [Metadata.clientRecordId] = "fudai_<uuid>" so we can
 *   dedup in-app vs external writes and delete our own records cleanly.
 * - Nutrition records include macros + 9 micronutrients (fiber, sugar, sat fat,
 *   cholesterol, sodium, potassium — plus monounsaturated/polyunsaturated when
 *   the AI provides them).
 * - The "typesVersion" integer bumps when we add new record types so existing
 *   users get a re-authorization prompt.
 */
class HealthConnectManager(private val context: Context) {

    private val client: HealthConnectClient? by lazy {
        runCatching { HealthConnectClient.getOrCreate(context) }.getOrNull()
    }

    fun isAvailable(): Boolean =
        HealthConnectClient.getSdkStatus(context) == HealthConnectClient.SDK_AVAILABLE

    val permissions: Set<String> = setOf(
        HealthPermission.getReadPermission(WeightRecord::class),
        HealthPermission.getWritePermission(WeightRecord::class),
        HealthPermission.getReadPermission(NutritionRecord::class),
        HealthPermission.getWritePermission(NutritionRecord::class)
    )

    suspend fun hasAllPermissions(): Boolean {
        val c = client ?: return false
        val granted = c.permissionController.getGrantedPermissions()
        return granted.containsAll(permissions)
    }

    /** Used to build the permission-request ActivityResultContract on the UI side. */
    fun permissionRequestContract() = PermissionController.createRequestPermissionResultContract()

    // -- Weight -----------------------------------------------------------

    suspend fun writeWeight(entry: WeightEntry): Boolean {
        val c = client ?: return false
        val record = WeightRecord(
            time = entry.date,
            zoneOffset = null,
            weight = Mass.kilograms(entry.weightKg),
            metadata = Metadata.manualEntry(clientRecordId = tag(entry.id))
        )
        return runCatching { c.insertRecords(listOf(record)) }.isSuccess
    }

    suspend fun deleteWeight(entryId: UUID): Boolean {
        val c = client ?: return false
        return runCatching {
            c.deleteRecords(
                recordType = WeightRecord::class,
                recordIdsList = emptyList(),
                clientRecordIdsList = listOf(tag(entryId))
            )
        }.isSuccess
    }

    suspend fun readWeights(from: Instant, to: Instant): List<ExternalWeight> {
        val c = client ?: return emptyList()
        val response = runCatching {
            c.readRecords(
                ReadRecordsRequest(
                    recordType = WeightRecord::class,
                    timeRangeFilter = TimeRangeFilter.between(from, to)
                )
            )
        }.getOrNull() ?: return emptyList()
        return response.records.map {
            ExternalWeight(
                time = it.time,
                weightKg = it.weight.inKilograms,
                clientRecordId = it.metadata.clientRecordId
            )
        }
    }

    // -- Nutrition --------------------------------------------------------

    suspend fun writeNutrition(entry: FoodEntry): Boolean {
        val c = client ?: return false
        val start = entry.timestamp
        // Nutrition records need a non-zero duration or Health Connect rejects them; use 1 minute.
        val end = start.plusSeconds(60)
        val record = NutritionRecord(
            startTime = start,
            endTime = end,
            startZoneOffset = null,
            endZoneOffset = null,
            name = entry.name,
            mealType = mealTypeFor(entry.mealType),
            energy = Energy.kilocalories(entry.calories.toDouble()),
            protein = Mass.grams(entry.protein.toDouble()),
            totalCarbohydrate = Mass.grams(entry.carbs.toDouble()),
            totalFat = Mass.grams(entry.fat.toDouble()),
            dietaryFiber = entry.fiber?.let { Mass.grams(it) },
            sugar = entry.sugar?.let { Mass.grams(it) },
            saturatedFat = entry.saturatedFat?.let { Mass.grams(it) },
            monounsaturatedFat = entry.monounsaturatedFat?.let { Mass.grams(it) },
            polyunsaturatedFat = entry.polyunsaturatedFat?.let { Mass.grams(it) },
            cholesterol = entry.cholesterol?.let { Mass.milligrams(it) },
            sodium = entry.sodium?.let { Mass.milligrams(it) },
            potassium = entry.potassium?.let { Mass.milligrams(it) },
            metadata = Metadata.manualEntry(clientRecordId = tag(entry.id))
        )
        return runCatching { c.insertRecords(listOf(record)) }.isSuccess
    }

    suspend fun updateNutrition(entry: FoodEntry): Boolean {
        // Health Connect doesn't allow true updates across clientRecordIds; delete-then-write
        // preserves the UUID linkage.
        deleteNutrition(entry.id)
        return writeNutrition(entry)
    }

    suspend fun deleteNutrition(entryId: UUID): Boolean {
        val c = client ?: return false
        return runCatching {
            c.deleteRecords(
                recordType = NutritionRecord::class,
                recordIdsList = emptyList(),
                clientRecordIdsList = listOf(tag(entryId))
            )
        }.isSuccess
    }

    // -- Change observation (external weight imports) --------------------

    /** Opaque token used to fetch incremental changes. Call once, persist, pass back later. */
    suspend fun getChangesToken(): String? {
        val c = client ?: return null
        return runCatching {
            c.getChangesToken(
                androidx.health.connect.client.request.ChangesTokenRequest(
                    recordTypes = setOf(WeightRecord::class)
                )
            )
        }.getOrNull()
    }

    /** Returns observed external weight upserts since [sinceToken] plus the next token to use. */
    suspend fun consumeWeightChanges(sinceToken: String): Pair<List<ExternalWeight>, String?>? {
        val c = client ?: return null
        val changes = runCatching { c.getChanges(sinceToken) }.getOrNull() ?: return null
        val upserts = changes.changes.filterIsInstance<UpsertionChange>()
        val results = upserts.mapNotNull { change ->
            val rec = change.record as? WeightRecord ?: return@mapNotNull null
            // Filter out samples we wrote ourselves (prefix matches our tag).
            val cid = rec.metadata.clientRecordId
            if (cid != null && cid.startsWith(CLIENT_PREFIX)) return@mapNotNull null
            ExternalWeight(
                time = rec.time,
                weightKg = rec.weight.inKilograms,
                clientRecordId = cid
            )
        }
        // Log deletions so callers can reconcile if desired.
        @Suppress("UNUSED_VARIABLE")
        val deletions = changes.changes.filterIsInstance<DeletionChange>()
        return results to changes.nextChangesToken
    }

    private fun tag(id: UUID): String = "$CLIENT_PREFIX${id}"

    private fun mealTypeFor(meal: com.apoorvdarshan.calorietracker.models.MealType): Int = when (meal) {
        com.apoorvdarshan.calorietracker.models.MealType.BREAKFAST -> HCMealType.MEAL_TYPE_BREAKFAST
        com.apoorvdarshan.calorietracker.models.MealType.LUNCH -> HCMealType.MEAL_TYPE_LUNCH
        com.apoorvdarshan.calorietracker.models.MealType.DINNER -> HCMealType.MEAL_TYPE_DINNER
        com.apoorvdarshan.calorietracker.models.MealType.SNACK -> HCMealType.MEAL_TYPE_SNACK
        com.apoorvdarshan.calorietracker.models.MealType.OTHER -> HCMealType.MEAL_TYPE_UNKNOWN
    }

    companion object {
        private const val CLIENT_PREFIX = "fudai_"

        /** Bump this when we add a new record type so users re-auth. */
        const val CURRENT_TYPES_VERSION = 1
    }
}

data class ExternalWeight(
    val time: Instant,
    val weightKg: Double,
    val clientRecordId: String?
) {
    @Suppress("unused")
    val zoneOffset: ZoneOffset? get() = null
}
