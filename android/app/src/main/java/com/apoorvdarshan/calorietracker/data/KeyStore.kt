package com.apoorvdarshan.calorietracker.data

import android.content.Context
import android.content.SharedPreferences
import androidx.security.crypto.EncryptedSharedPreferences
import androidx.security.crypto.MasterKey
import com.apoorvdarshan.calorietracker.models.AIProvider
import com.apoorvdarshan.calorietracker.models.SpeechProvider

/**
 * Encrypted per-provider API key storage — the Android equivalent of iOS Keychain.
 * Backed by EncryptedSharedPreferences (AES-256).
 */
class KeyStore(context: Context) {
    private val prefs: SharedPreferences

    init {
        val masterKey = MasterKey.Builder(context)
            .setKeyScheme(MasterKey.KeyScheme.AES256_GCM)
            .build()
        prefs = EncryptedSharedPreferences.create(
            context,
            FILE_NAME,
            masterKey,
            EncryptedSharedPreferences.PrefKeyEncryptionScheme.AES256_SIV,
            EncryptedSharedPreferences.PrefValueEncryptionScheme.AES256_GCM
        )
    }

    fun save(key: String, value: String) {
        prefs.edit().putString(key, value).apply()
    }

    fun load(key: String): String? = prefs.getString(key, null)

    fun delete(key: String) {
        prefs.edit().remove(key).apply()
    }

    // AI providers
    fun apiKey(provider: AIProvider): String? = load(AI_PREFIX + provider.name)
    fun setApiKey(provider: AIProvider, key: String?) {
        val storageKey = AI_PREFIX + provider.name
        if (key.isNullOrEmpty()) delete(storageKey) else save(storageKey, key)
    }

    // Speech providers
    fun speechApiKey(provider: SpeechProvider): String? = load(STT_PREFIX + provider.name)
    fun setSpeechApiKey(provider: SpeechProvider, key: String?) {
        val storageKey = STT_PREFIX + provider.name
        if (key.isNullOrEmpty()) delete(storageKey) else save(storageKey, key)
    }

    fun clearAll() {
        prefs.edit().clear().apply()
    }

    companion object {
        private const val FILE_NAME = "fudai_keychain"
        private const val AI_PREFIX = "apikey_"
        private const val STT_PREFIX = "speechApiKey_"
    }
}
