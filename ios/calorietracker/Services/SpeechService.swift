import Foundation

/// Audio transcription. Records m4a locally, uploads through BackendClient
/// which delegates to whichever provider is configured server-side. Native
/// iOS streaming transcription lives in VoiceInputView itself when the
/// device + locale support it; this service only handles the upload path.
struct SpeechService {
    enum SpeechError: LocalizedError {
        case fileReadFailed
        case backend(BackendClient.BackendError)
        case invalidResponse

        var errorDescription: String? {
            switch self {
            case .fileReadFailed:
                return String(localized: "Could not read the recorded audio file.")
            case .backend(let err):
                return err.errorDescription
            case .invalidResponse:
                return String(localized: "Unexpected response from the speech provider.")
            }
        }
    }

    static func transcribe(audioURL: URL, languageCode: String? = nil) async throws -> String {
        guard let audioData = try? Data(contentsOf: audioURL) else {
            throw SpeechError.fileReadFailed
        }
        do {
            return try await BackendClient.transcribe(
                audioData: audioData,
                mimeType: "audio/m4a",
                languageCode: languageCode
            )
        } catch let err as BackendClient.BackendError {
            throw SpeechError.backend(err)
        }
    }
}
