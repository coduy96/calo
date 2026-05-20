import SwiftUI
import AVFoundation
import UIKit

/// Voice input flow: record m4a → upload to the backend → show transcript.
/// All transcription happens server-side (the paid feature); no on-device
/// streaming. Recording auto-stops at 60s to keep the audio payload small.
struct VoiceInputView: View {
    @State private var transcription = ""
    @State private var isRecording = false
    @State private var isTranscribing = false
    @State private var permissionError: String?
    @State private var remoteNotice: String?

    @State private var audioRecorder: AVAudioRecorder?
    @State private var recordedFileURL: URL?
    @State private var recordingLimitTask: Task<Void, Never>?

    @State private var samples: [CGFloat] = Array(repeating: 0, count: VoiceInputView.sampleCount)
    @State private var elapsed: TimeInterval = 0
    @State private var meterTimer: Timer?
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6
    @State private var didWarnNearLimit = false

    var onCancel: () -> Void
    var onSubmit: (String) -> Void

    private static let sampleCount = 40
    private let maxRecordingSeconds: TimeInterval = 60

    private var progress: CGFloat {
        let value = 1 - CGFloat(elapsed / maxRecordingSeconds)
        return max(0, min(1, value))
    }

    private var timeLabel: String {
        let total = Int(elapsed.rounded())
        return String(format: "%d:%02d / 1:00", total / 60, total % 60)
    }

    private var isInFinalCountdown: Bool {
        maxRecordingSeconds - elapsed <= 10 && isRecording
    }

    private var analyzeButtonDisabled: Bool {
        if isRecording || isTranscribing { return true }
        return transcription.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            backgroundLayer
                .ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                Spacer(minLength: 16)

                transcriptCard
                    .padding(.horizontal, 20)

                Spacer(minLength: 12)

                WaveformStrip(samples: samples, isActive: isRecording)
                    .frame(height: 64)
                    .padding(.horizontal, 24)
                    .opacity(isRecording ? 1.0 : (transcription.isEmpty ? 0.2 : 0.0))
                    .animation(.easeInOut(duration: 0.25), value: isRecording)

                Spacer(minLength: 12)

                micButton
                    .padding(.vertical, 8)

                Spacer(minLength: 16)

                bottomActions
                    .padding(.horizontal, 20)
                    .padding(.bottom, 12)
            }
        }
        .onAppear { startRecording() }
        .onDisappear {
            invalidateMeterTimer()
            stopRecording(skipTranscription: true)
        }
    }

    // MARK: - Subviews

    private var backgroundLayer: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                AppColors.calorie.opacity(0.08),
                Color(.systemBackground),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var topBar: some View {
        HStack {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                stopRecording(skipTranscription: true)
                onCancel()
            } label: {
                Image(systemName: "xmark.circle.fill")
                    .font(.system(size: 30))
                    .foregroundStyle(.secondary)
                    .symbolRenderingMode(.hierarchical)
            }
            .accessibilityLabel("Close")

            Spacer()

            Text(timeLabel)
                .font(.system(.callout, design: .rounded).monospacedDigit())
                .fontWeight(.semibold)
                .foregroundStyle(isInFinalCountdown ? Color.red : .secondary)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(
                    Capsule()
                        .fill(.ultraThinMaterial)
                )
                .accessibilityLabel("\(Int((maxRecordingSeconds - elapsed).rounded())) seconds remaining")
        }
    }

    private var transcriptCard: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(AppColors.calorie.opacity(0.22), lineWidth: 1)
                )
                .shadow(color: AppColors.calorie.opacity(0.08), radius: 18, x: 0, y: 8)

            Group {
                if isTranscribing {
                    VoidpenLoadingCompact(label: Text("Transcribing…"))
                        .padding(20)
                } else if transcription.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(isRecording ? "Listening…" : "Tap the mic to start")
                            .font(.system(.title3, design: .rounded, weight: .semibold))
                            .foregroundStyle(.primary)
                        Text(isRecording ? "Describe what you ate. We'll stop at 60s." : "Tell us what you ate — meals, drinks, snacks.")
                            .font(.footnote)
                            .foregroundStyle(.secondary)
                    }
                    .padding(20)
                    .frame(maxWidth: .infinity, alignment: .topLeading)
                } else {
                    TextEditor(text: $transcription)
                        .font(.body)
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 12)
                        .accessibilityLabel("Transcription")
                }
            }

            if let error = permissionError {
                VStack {
                    Spacer()
                    HStack(spacing: 6) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                        Text(error)
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                    }
                    .foregroundStyle(.red)
                    .padding(.horizontal, 14)
                    .padding(.bottom, 10)
                }
            } else if let notice = remoteNotice {
                VStack {
                    Spacer()
                    Text(notice)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.leading)
                        .padding(.horizontal, 14)
                        .padding(.bottom, 10)
                }
            }
        }
        .frame(minHeight: 160)
        .animation(.easeInOut(duration: 0.2), value: isTranscribing)
        .animation(.easeInOut(duration: 0.2), value: transcription.isEmpty)
    }

    private var micButton: some View {
        ZStack {
            // Outer pulse ring (only when recording)
            if isRecording {
                Circle()
                    .stroke(AppColors.calorie.opacity(0.5), lineWidth: 2)
                    .frame(width: 120, height: 120)
                    .scaleEffect(pulseScale)
                    .opacity(pulseOpacity)
            }

            // Countdown ring
            Circle()
                .stroke(Color.secondary.opacity(0.12), lineWidth: 4)
                .frame(width: 116, height: 116)

            Circle()
                .trim(from: 0, to: progress)
                .stroke(
                    LinearGradient(
                        colors: isInFinalCountdown
                            ? [Color.red, Color.orange]
                            : AppColors.calorieGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    style: StrokeStyle(lineWidth: 4, lineCap: .round)
                )
                .frame(width: 116, height: 116)
                .rotationEffect(.degrees(-90))
                .animation(.linear(duration: 0.1), value: progress)

            // Mic button
            Button {
                if isRecording {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    stopRecording()
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    startRecording()
                }
            } label: {
                Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(width: 96, height: 96)
                    .background(
                        Circle()
                            .fill(
                                LinearGradient(
                                    colors: AppColors.calorieGradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: AppColors.calorie.opacity(isRecording ? 0.55 : 0.35), radius: 24, x: 0, y: 10)
                    .shadow(color: AppColors.calorie.opacity(isRecording ? 0.35 : 0.0), radius: 40, x: 0, y: 0)
                    .opacity(isTranscribing ? 0.6 : 1.0)
            }
            .disabled(isTranscribing)
            .accessibilityLabel(isRecording ? "Stop recording" : "Start recording")
            .accessibilityHint("Records up to 60 seconds of voice for meal logging.")
        }
        .onChange(of: isRecording) { _, recording in
            if recording {
                pulseScale = 1.0
                pulseOpacity = 0.7
                withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                    pulseScale = 1.6
                    pulseOpacity = 0.0
                }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    pulseScale = 1.0
                    pulseOpacity = 0.6
                }
            }
        }
    }

    private var bottomActions: some View {
        VStack(spacing: 12) {
            if !transcription.isEmpty && !isRecording && !isTranscribing {
                Button {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    transcription = ""
                    remoteNotice = nil
                    permissionError = nil
                    startRecording()
                } label: {
                    HStack(spacing: 8) {
                        Image(systemName: "arrow.counterclockwise")
                            .font(.system(size: 14, weight: .semibold))
                        Text("Re-record")
                            .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    }
                    .foregroundStyle(AppColors.calorie)
                    .padding(.horizontal, 18)
                    .padding(.vertical, 10)
                    .background(
                        Capsule()
                            .fill(.ultraThinMaterial)
                            .overlay(
                                Capsule()
                                    .strokeBorder(AppColors.calorie.opacity(0.35), lineWidth: 1)
                            )
                    )
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            }

            Button {
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                onSubmit(transcription)
            } label: {
                Text("Analyze")
                    .font(.system(.headline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.white)
                    .frame(maxWidth: .infinity)
                    .frame(height: 56)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(
                                LinearGradient(
                                    colors: AppColors.calorieGradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    )
                    .shadow(color: AppColors.calorie.opacity(analyzeButtonDisabled ? 0.0 : 0.35), radius: 14, x: 0, y: 6)
                    .opacity(analyzeButtonDisabled ? 0.45 : 1.0)
            }
            .disabled(analyzeButtonDisabled)
        }
        .animation(.easeInOut(duration: 0.25), value: transcription.isEmpty)
        .animation(.easeInOut(duration: 0.25), value: isRecording)
        .animation(.easeInOut(duration: 0.25), value: isTranscribing)
    }

    // MARK: - Recording

    private func startRecording() {
        permissionError = nil
        remoteNotice = nil
        transcription = ""
        didWarnNearLimit = false
        elapsed = 0
        samples = Array(repeating: 0, count: VoiceInputView.sampleCount)
        AVAudioApplication.requestRecordPermission { allowed in
            DispatchQueue.main.async {
                guard allowed else {
                    UINotificationFeedbackGenerator().notificationOccurred(.error)
                    permissionError = String(localized: "Microphone permission denied. Enable it in Settings.")
                    return
                }
                beginRecording()
            }
        }
    }

    private func beginRecording() {
        let session = AVAudioSession.sharedInstance()
        do {
            try session.setCategory(.record, mode: .default, options: .duckOthers)
            try session.setActive(true, options: .notifyOthersOnDeactivation)
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
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
            let recorder = try AVAudioRecorder(url: fileURL, settings: settings)
            recorder.isMeteringEnabled = true
            recorder.record()
            audioRecorder = recorder
            isRecording = true
            startMeterTimer()
            startRecordingLimit()
        } catch {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            permissionError = String(localized: "Failed to start recording: \(error.localizedDescription)")
        }
    }

    private func stopRecording(skipTranscription: Bool = false) {
        guard isRecording || audioRecorder != nil else { return }
        recordingLimitTask?.cancel()
        recordingLimitTask = nil
        invalidateMeterTimer()
        audioRecorder?.stop()
        audioRecorder = nil
        isRecording = false
        try? AVAudioSession.sharedInstance().setActive(false, options: .notifyOthersOnDeactivation)

        guard let fileURL = recordedFileURL else { return }
        recordedFileURL = nil

        if skipTranscription {
            try? FileManager.default.removeItem(at: fileURL)
            return
        }

        isTranscribing = true
        Task {
            defer { isTranscribing = false }
            do {
                let languageCode = Locale.autoupdatingCurrent.language.languageCode?.identifier.lowercased()
                let text = try await SpeechService.transcribe(audioURL: fileURL, languageCode: languageCode)
                transcription = text
                UINotificationFeedbackGenerator().notificationOccurred(.success)
            } catch {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                permissionError = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
            try? FileManager.default.removeItem(at: fileURL)
        }
    }

    private func startMeterTimer() {
        invalidateMeterTimer()
        let timer = Timer.scheduledTimer(withTimeInterval: 0.05, repeats: true) { _ in
            guard let recorder = audioRecorder, isRecording else { return }
            recorder.updateMeters()
            let db = recorder.averagePower(forChannel: 0)
            let normalized = normalizedPower(db: db)
            var next = samples
            next.removeFirst()
            next.append(CGFloat(normalized))
            samples = next

            elapsed = min(elapsed + 0.05, maxRecordingSeconds)

            if !didWarnNearLimit && (maxRecordingSeconds - elapsed) <= 10 {
                didWarnNearLimit = true
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
            }
        }
        meterTimer = timer
        RunLoop.main.add(timer, forMode: .common)
    }

    private func invalidateMeterTimer() {
        meterTimer?.invalidate()
        meterTimer = nil
    }

    private func normalizedPower(db: Float) -> Float {
        // averagePower returns dBFS in roughly [-160, 0]. Treat anything below
        // -55 as silence so quiet noise floor doesn't visually fill the bars.
        guard db.isFinite else { return 0 }
        let floor: Float = -55
        let clamped = max(floor, min(0, db))
        return (clamped - floor) / -floor
    }

    private func startRecordingLimit() {
        recordingLimitTask?.cancel()
        recordingLimitTask = Task {
            try? await Task.sleep(for: .seconds(Int(maxRecordingSeconds)))
            guard !Task.isCancelled else { return }
            await MainActor.run {
                guard isRecording else { return }
                remoteNotice = String(localized: "60-second limit reached. Transcribing your meal now.")
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                stopRecording()
            }
        }
    }
}

// MARK: - Waveform

private struct WaveformStrip: View {
    let samples: [CGFloat]
    let isActive: Bool

    var body: some View {
        GeometryReader { geo in
            let barCount = samples.count
            let totalSpacing = CGFloat(barCount - 1) * 3
            let barWidth = max(2, (geo.size.width - totalSpacing) / CGFloat(barCount))
            HStack(spacing: 3) {
                ForEach(0..<barCount, id: \.self) { i in
                    Capsule(style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: AppColors.calorieGradient,
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                        .frame(
                            width: barWidth,
                            height: max(3, samples[i] * geo.size.height)
                        )
                        .animation(.easeOut(duration: 0.08), value: samples[i])
                }
            }
            .frame(width: geo.size.width, height: geo.size.height, alignment: .center)
        }
        .accessibilityHidden(true)
    }
}
