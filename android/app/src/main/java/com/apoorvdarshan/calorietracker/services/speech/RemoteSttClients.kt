package com.apoorvdarshan.calorietracker.services.speech

import kotlinx.coroutines.Dispatchers
import kotlinx.coroutines.delay
import kotlinx.coroutines.withContext
import okhttp3.MediaType.Companion.toMediaType
import okhttp3.MultipartBody
import okhttp3.OkHttpClient
import okhttp3.Request
import okhttp3.RequestBody.Companion.asRequestBody
import okhttp3.RequestBody.Companion.toRequestBody
import org.json.JSONObject
import java.io.File
import java.io.IOException

sealed class SttApiError(message: String) : Exception(message) {
    object NoApiKey : SttApiError("No STT API key configured.")
    class Network(cause: Throwable) : SttApiError("Network error: ${cause.localizedMessage}")
    class Api(msg: String) : SttApiError(msg)
    object InvalidResponse : SttApiError("Could not understand the transcription response.")
    object Timeout : SttApiError("Transcription timed out.")
}

/**
 * OpenAI Whisper + Groq share /v1/audio/transcriptions (multipart).
 */
object WhisperClient {
    suspend fun transcribe(
        client: OkHttpClient,
        baseUrl: String,
        apiKey: String,
        model: String,
        audio: File
    ): String = withContext(Dispatchers.IO) {
        val body = MultipartBody.Builder()
            .setType(MultipartBody.FORM)
            .addFormDataPart("model", model)
            .addFormDataPart("file", audio.name, audio.asRequestBody("audio/m4a".toMediaType()))
            .build()
        val req = Request.Builder()
            .url("$baseUrl/audio/transcriptions")
            .addHeader("Authorization", "Bearer $apiKey")
            .post(body)
            .build()
        runRequest(client, req)
    }
}

/**
 * Deepgram: raw audio body, Token auth.
 */
object DeepgramClient {
    suspend fun transcribe(
        client: OkHttpClient,
        apiKey: String,
        model: String,
        audio: File
    ): String = withContext(Dispatchers.IO) {
        val req = Request.Builder()
            .url("https://api.deepgram.com/v1/listen?model=$model&punctuate=true&smart_format=true")
            .addHeader("Authorization", "Token $apiKey")
            .addHeader("Content-Type", "audio/m4a")
            .post(audio.asRequestBody("audio/m4a".toMediaType()))
            .build()
        val body = runRequestRaw(client, req)
        runCatching {
            JSONObject(body)
                .getJSONObject("results")
                .getJSONArray("channels")
                .getJSONObject(0)
                .getJSONArray("alternatives")
                .getJSONObject(0)
                .getString("transcript")
        }.getOrNull() ?: throw SttApiError.InvalidResponse
    }
}

/**
 * AssemblyAI: 3-step upload -> submit -> poll every 1s up to 60s.
 */
object AssemblyAIClient {
    suspend fun transcribe(
        client: OkHttpClient,
        apiKey: String,
        audio: File
    ): String = withContext(Dispatchers.IO) {
        // 1. Upload
        val uploadReq = Request.Builder()
            .url("https://api.assemblyai.com/v2/upload")
            .addHeader("authorization", apiKey)
            .post(audio.asRequestBody("audio/m4a".toMediaType()))
            .build()
        val uploadJson = JSONObject(runRequestRaw(client, uploadReq))
        val audioUrl = uploadJson.optString("upload_url").takeIf { it.isNotEmpty() }
            ?: throw SttApiError.InvalidResponse

        // 2. Submit
        val submitBody = JSONObject().put("audio_url", audioUrl).toString()
            .toRequestBody("application/json".toMediaType())
        val submitReq = Request.Builder()
            .url("https://api.assemblyai.com/v2/transcript")
            .addHeader("authorization", apiKey)
            .post(submitBody)
            .build()
        val submitJson = JSONObject(runRequestRaw(client, submitReq))
        val transcriptId = submitJson.optString("id").takeIf { it.isNotEmpty() }
            ?: throw SttApiError.InvalidResponse

        // 3. Poll
        repeat(60) {
            delay(1_000)
            val pollReq = Request.Builder()
                .url("https://api.assemblyai.com/v2/transcript/$transcriptId")
                .addHeader("authorization", apiKey)
                .get()
                .build()
            val pollJson = JSONObject(runRequestRaw(client, pollReq))
            when (pollJson.optString("status")) {
                "completed" -> return@withContext pollJson.optString("text").orEmpty()
                "error" -> throw SttApiError.Api(pollJson.optString("error", "AssemblyAI error"))
            }
        }
        throw SttApiError.Timeout
    }
}

// Shared helpers -------------------------------------------------------

private suspend fun runRequest(client: OkHttpClient, req: Request): String {
    val body = runRequestRaw(client, req)
    return runCatching {
        JSONObject(body).optString("text").takeIf { it.isNotEmpty() }
    }.getOrNull() ?: throw SttApiError.InvalidResponse
}

private suspend fun runRequestRaw(client: OkHttpClient, req: Request): String = withContext(Dispatchers.IO) {
    try {
        client.newCall(req).execute().use { resp ->
            val str = resp.body?.string().orEmpty()
            if (!resp.isSuccessful) throw SttApiError.Api("STT HTTP ${resp.code}: ${str.take(200)}")
            str
        }
    } catch (io: IOException) {
        throw SttApiError.Network(io)
    }
}
