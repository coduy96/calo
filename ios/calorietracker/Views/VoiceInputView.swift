import SwiftUI
import AVFoundation

/// Voice input flow: record m4a → upload to the backend → show transcript.
/// All transcription happens server-side (the paid feature); no on-device
/// streaming. Recording auto-stops at 60s to keep the audio payload small.
struct VoiceInputView: View {
    @State private var transcription = ""
    @State private var isRecording = false
    @State private var isTranscribing = false
    @State private var permissionError: String?
    @State private var remoteNotice: String?
    @State private var pulseScale: CGFloat = 1.0

    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordedFileURL: URL?
    @State private var recordingLimitTask: Task<Void, Never>?

    var onCancel: () -> Void
    var onSubmit: (String) -> Void

    private let maxRecordingSeconds = 60

    private var analyzeButtonDisabled: Bool {
        if isRecording || isTranscribing { return true }
        return transcription.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        VStack(spacing: 20) {
            // Transcription area
            ZStack(alignment: .topLeading) {
                if transcription.isEmpty && !isTranscribing {
                    Text(isRecording ? LocalizedStringKey("Listening…") : LocalizedStringKey("Tap the mic to start"))
                        .foregroundStyle(.tertiary)
                        .font(.body)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 10)
                        .allowsHitTesting(false)
                }

                if isTranscribing {
                    VoidpenLoadingCompact(
                        label: Text("Transcribing…")
                    )
                    .padding(.horizontal, 6)
                    .padding(.vertical, 10)
                }

                Text(transcription)
                    .font(.body)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 10)
            }
            .padding(12)
            .frame(minHeight: 100, alignment: .topLeading)
            .background(
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.quaternarySystemFill))
            )

            // Mic button
            Button {
                if isRecording {
                    stopRecording()
                } else {
                    startRecording()
                }
            } label: {
                Image(systemName: isRecording ? "mic.fill" : "mic")
                    .font(.system(size: 28))
                    .foregroundStyle(.white)
                    .frame(width: 72, height: 72)
                    .background(
                        Circle()
                            .fill(isRecording ? Color.red : AppColors.calorie)
                    )
                    .scaleEffect(pulseScale)
            }
            .disabled(isTranscribing)
            .onChange(of: isRecording) { _, recording in
                if recording {
                    withAnimation(.easeInOut(duration: 0.8).repeatForever(autoreverses: true)) {
                        pulseScale = 1.15
                    }
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        pulseScale = 1.0
                    }
                }
            }

            if let error = permissionError {
                Text(error)
                    .font(.caption)
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
            }

            if let notice = remoteNotice {
                Text(notice)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Text("Voice recordings are capped at 60 seconds.")
                .font(.caption)
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)

            Button {
                onSubmit(transcription)
            } label: {
                Text("Analyze")
                    .font(.headline)
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
            .tint(AppColors.calorie)
            .controlSize(.large)
            .disabled(analyzeButtonDisabled)

            Button("Cancel") {
                stopRecording()
                onCancel()
            }
            .foregroundStyle(.secondary)
        }
        .padding(20)
        .frame(width: 320)
        .onAppear { startRecording() }
        .onDisappear { stopRecording() }
    }

    // MARK: - Recording

    private func startRecording() {
        permissionError = nil
        remoteNotice = nil
        transcription = ""
        AVAudioApplication.requestRecordPermission { allowed in
            guard allowed else {
                permissionError = String(localized: "Microphone permission denied. Enable it in Settings.")
                return
            }
            beginRecording()
        }
    }

    private func beginRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .default, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            permissionError = String(localized: "Failed to set up audio session.")
            return
        }

        let fileURL = FileManager.default.temporaryDirectory.appendingPathComponent("voice-\(UUID().uuidString).m4a")
        recordedFileURL = fileURL

        let settings: [String: Any] = [
            AVFormatIDKey: Int(kAudioFormatMPEG4AAC),
            AVSampleRateKey: 16_000,
            AVNumberOfChannelsKey: 1,
            AVEncoderAudioQualityKey: AVAudioQuality.medium.rawValue,
        ]
        do {
            audioRecorder = try AVAudioRecorder(url: fileURL, settings: settings)
            audioRecorder?.record()
            isRecording = true
            startRecordingLimit()
        } catch {
            permissionError = String(localized: "Failed to start recording: \(error.localizedDescription)")
        }
    }

    private func stopRecording() {
        guard isRecording || audioRecorder != nil else { return }
        recordingLimitTask?.cancel()
        recordingLimitTask = nil
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        guard let fileURL = recordedFileURL else { return }
        recordedFileURL = nil

        isTranscribing = true
        Task {
            defer { isTranscribing = false }
            do {
                let languageCode = Locale.autoupdatingCurrent.language.languageCode?.identifier.lowercased()
                let text = try await SpeechService.transcribe(audioURL: fileURL, languageCode: languageCode)
                transcription = text
            } catch {
                permissionError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    private func startRecordingLimit() {
        recordingLimitTask?.cancel()
        recordingLimitTask = Task {
            try? await Task.sleep(for: .seconds(maxRecordingSeconds))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard isRecording else { return }
                remoteNotice = String(localized: "60-second limit reached. Transcribing your meal now.")
                stopRecording()
            }
        }
    }
}
