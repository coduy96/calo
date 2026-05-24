import Foundation
import AVFoundation
import Combine
import Speech

/// Live, on-device speech recognition. Owns an `AVAudioEngine` mic tap and
/// streams PCM buffers into `SFSpeechAudioBufferRecognitionRequest` so the
/// transcript updates in real time as the user speaks. Falls back to Apple's
/// server recognizer when the chosen locale lacks an on-device model.
enum SpeechService {
    enum SpeechError: LocalizedError {
        case micNotAuthorized
        case speechNotAuthorized
        case recognizerUnavailable
        case audioSessionFailed(Error)
        case audioEngineFailed(Error)
        case recognitionFailed(Error)
        case noSpeechDetected

        var errorDescription: String? {
            switch self {
            case .micNotAuthorized:
                return String(localized: "Microphone permission denied. Enable it in Settings.")
            case .speechNotAuthorized:
                return String(localized: "Speech recognition permission denied. Enable it in Settings.")
            case .recognizerUnavailable:
                return String(localized: "Speech recognition isn't available for this language.")
            case .audioSessionFailed:
                return String(localized: "Failed to set up audio session.")
            case .audioEngineFailed(let err):
                return String(localized: "Failed to start recording: \(err.localizedDescription)")
            case .recognitionFailed(let err):
                return String(localized: "Couldn't transcribe: \(err.localizedDescription)")
            case .noSpeechDetected:
                return String(localized: "No speech detected — try again.")
            }
        }
    }

    static func ensureMicAuthorized() async -> Bool {
        switch AVAudioApplication.shared.recordPermission {
        case .granted: return true
        case .denied: return false
        case .undetermined:
            return await withCheckedContinuation { cont in
                AVAudioApplication.requestRecordPermission { cont.resume(returning: $0) }
            }
        @unknown default: return false
        }
    }

    static func ensureSpeechAuthorized() async -> Bool {
        switch SFSpeechRecognizer.authorizationStatus() {
        case .authorized: return true
        case .denied, .restricted: return false
        case .notDetermined:
            return await withCheckedContinuation { cont in
                SFSpeechRecognizer.requestAuthorization { cont.resume(returning: $0 == .authorized) }
            }
        @unknown default: return false
        }
    }
}

@MainActor
final class LiveTranscriber: ObservableObject {
    @Published private(set) var transcript: String = ""
    @Published private(set) var isRunning: Bool = false
    @Published private(set) var error: SpeechService.SpeechError?

    private let audioEngine = AVAudioEngine()
    private var request: SFSpeechAudioBufferRecognitionRequest?
    private var task: SFSpeechRecognitionTask?

    // Audio tap runs off the main thread; the lock guards the latest dB read
    // by the UI's metering loop without per-buffer main-actor hops.
    private let dbLock = NSLock()
    private var _currentDb: Float = -160

    func currentDb() -> Float {
        dbLock.lock(); defer { dbLock.unlock() }
        return _currentDb
    }

    func start(languageCode: String? = nil) async {
        stopInternal()
        transcript = ""
        error = nil
        setDb(-160)

        guard await SpeechService.ensureMicAuthorized() else {
            error = .micNotAuthorized; return
        }
        guard await SpeechService.ensureSpeechAuthorized() else {
            error = .speechNotAuthorized; return
        }

        let locale = languageCode.map { Locale(identifier: $0) } ?? Locale.autoupdatingCurrent
        let recognizer = SFSpeechRecognizer(locale: locale) ?? SFSpeechRecognizer()
        guard let recognizer, recognizer.isAvailable else {
            error = .recognizerUnavailable; return
        }

        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.playAndRecord, mode: .measurement, options: [.duckOthers, .defaultToSpeaker])
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            self.error = .audioSessionFailed(error); return
        }

        // Hardware sanity check. On Simulator without "Audio Input → Internal
        // Microphone" enabled, or on real devices where the mic is busy with
        // another app, the HAL reports a 0 Hz sample rate. Starting the engine
        // in that state hangs CoreAudio with a SetProperty RPC timeout — so
        // bail here with a clear, actionable error instead.
        guard session.isInputAvailable, session.sampleRate > 0 else {
            try? session.setActive(false, options: .notifyOthersOnDeactivation)
            self.error = .audioEngineFailed(NSError(
                domain: "SpeechService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Microphone input unavailable. On Simulator, enable Device → Audio Input → Internal Microphone."]
            ))
            return
        }

        let req = SFSpeechAudioBufferRecognitionRequest()
        req.shouldReportPartialResults = true
        if recognizer.supportsOnDeviceRecognition {
            req.requiresOnDeviceRecognition = true
        }
        self.request = req

        // Clear any stale graph state before reattaching the tap. Without this
        // a second `start()` call can pick up an invalid input format.
        audioEngine.reset()
        let input = audioEngine.inputNode
        input.removeTap(onBus: 0)

        // Prefer the input-side format (what the mic delivers). Fall back to
        // outputFormat if needed.
        var format = input.inputFormat(forBus: 0)
        if format.sampleRate == 0 || format.channelCount == 0 {
            format = input.outputFormat(forBus: 0)
        }
        guard format.sampleRate > 0, format.channelCount > 0 else {
            self.request = nil
            self.error = .audioEngineFailed(NSError(
                domain: "SpeechService",
                code: -1,
                userInfo: [NSLocalizedDescriptionKey: "Microphone format unavailable."]
            ))
            return
        }

        input.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            self?.handleBuffer(buffer)
        }

        audioEngine.prepare()
        do {
            try audioEngine.start()
        } catch {
            input.removeTap(onBus: 0)
            self.request = nil
            self.error = .audioEngineFailed(error)
            return
        }

        self.task = recognizer.recognitionTask(with: req) { [weak self] result, taskError in
            guard let self else { return }
            DispatchQueue.main.async { self.handleRecognition(result: result, error: taskError) }
        }

        isRunning = true
    }

    func stop() {
        stopInternal()
    }

    private func stopInternal() {
        if audioEngine.isRunning {
            audioEngine.stop()
        }
        audioEngine.inputNode.removeTap(onBus: 0)
        request?.endAudio()
        // Keep `task` alive until the final result arrives so the closure can
        // deliver the last partial. It's released in `handleRecognition`.
        request = nil
        setDb(-160)
        isRunning = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)
    }

    private func handleRecognition(result: SFSpeechRecognitionResult?, error: Error?) {
        if let result {
            transcript = result.bestTranscription.formattedString
            if result.isFinal {
                task = nil
            }
        }
        if let error {
            let nserr = error as NSError
            // kAFAssistantErrorDomain 1110 = "no speech detected" — only surface
            // if we never got any partial text.
            let isNoSpeech = nserr.domain == "kAFAssistantErrorDomain" && nserr.code == 1110
            let hasText = !transcript.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
            if isNoSpeech && !hasText {
                self.error = .noSpeechDetected
            } else if !hasText {
                self.error = .recognitionFailed(error)
            }
            task = nil
        }
    }

    private func handleBuffer(_ buffer: AVAudioPCMBuffer) {
        request?.append(buffer)
        guard let channelData = buffer.floatChannelData?[0] else { return }
        let frameLength = Int(buffer.frameLength)
        guard frameLength > 0 else { return }
        var sumSquares: Float = 0
        for i in 0..<frameLength {
            let v = channelData[i]
            sumSquares += v * v
        }
        let rms = sqrt(sumSquares / Float(frameLength))
        let db: Float = rms > 0 ? 20 * log10(rms) : -160
        setDb(db)
    }

    private func setDb(_ db: Float) {
        dbLock.lock(); _currentDb = db; dbLock.unlock()
    }
}
