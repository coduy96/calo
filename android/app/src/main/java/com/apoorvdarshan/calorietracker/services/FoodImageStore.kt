package com.apoorvdarshan.calorietracker.services

import android.content.Context
import android.graphics.Bitmap
import android.graphics.BitmapFactory
import java.io.File
import java.io.FileOutputStream
import java.util.UUID

/**
 * Local food-photo cache. Port of iOS FoodImageStore.
 * JPEGs live under filesDir/fudai-food-images/{uuid}.jpg so they stay out of
 * the DataStore blob (which would otherwise inflate past quick-read limits).
 */
class FoodImageStore(context: Context) {
    private val dir: File = File(context.filesDir, DIR_NAME).apply { mkdirs() }

    /** Writes the bitmap as JPEG (quality 80) under a new filename. Returns filename or null. */
    fun store(bitmap: Bitmap, entryId: UUID): String? = runCatching {
        val filename = "${entryId}.jpg"
        FileOutputStream(File(dir, filename)).use { out ->
            bitmap.compress(Bitmap.CompressFormat.JPEG, 80, out)
        }
        filename
    }.getOrNull()

    fun storeBytes(bytes: ByteArray, entryId: UUID): String? = runCatching {
        val filename = "${entryId}.jpg"
        File(dir, filename).writeBytes(bytes)
        filename
    }.getOrNull()

    fun load(filename: String): Bitmap? =
        runCatching { BitmapFactory.decodeFile(File(dir, filename).absolutePath) }.getOrNull()

    fun file(filename: String): File = File(dir, filename)

    fun delete(filename: String) {
        runCatching { File(dir, filename).delete() }
    }

    fun clearAll() {
        dir.listFiles()?.forEach { runCatching { it.delete() } }
    }

    companion object {
        private const val DIR_NAME = "fudai-food-images"
    }
}
