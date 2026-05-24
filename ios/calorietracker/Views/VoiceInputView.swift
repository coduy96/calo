import SwiftUI
import AVFoundation
import UIKit

/// Voice input flow: live on-device transcription via SFSpeechRecognizer.
/// Text streams into the editable transcript as the user speaks. Auto-stops
/// after ~1.5s of silence; a generous 2-minute safety cap prevents a forgotten
/// session from draining the mic forever.
struct VoiceInputView: View {
    @StateObject private var transcriber = LiveTranscriber()

    @State private var transcription = ""
    @State private var isRecording = false
    @State private var isPreparing = false
    @State private var permissionError: String?

    @State private var recordingLimitTask: Task<Void, Never>?

    @State private var samples: [CGFloat] = Array(repeating: 0, count: VoiceInputView.sampleCount)
    @State private var elapsed: TimeInterval = 0
    @State private var meterTimer: Timer?
    @State private var pulseScale: CGFloat = 1.0
    @State private var pulseOpacity: Double = 0.6
    @State private var dotOpacity: Double = 1.0
    @State private var hasDetectedSpeech = false
    @State private var silenceAccumulated: TimeInterval = 0

    var onCancel: () -> Void
    var onSubmit: (String) -> Void

    private static let sampleCount = 56
    private let maxRecordingSeconds: TimeInterval = 120
    // dBFS gates for VAD. Speech must clear -28 dB once to "arm" the detector;
    // after that, any sample below -42 dB counts toward silenceAccumulated.
    private let speechActivationDb: Float = -28
    private let silenceThresholdDb: Float = -42
    private let silenceAutoStopSeconds: TimeInterval = 1.5
    private let minRecordingBeforeAutoStop: TimeInterval = 1.0

    private var elapsedLabel: String {
        let total = Int(elapsed.rounded())
        return String(format: "%d:%02d", total / 60, total % 60)
    }

    private var analyzeDisabled: Bool {
        if isRecording { return true }
        return transcription.trimmingCharacters(in: .whitespaces).isEmpty
    }

    var body: some View {
        ZStack {
            backgroundLayer.ignoresSafeArea()

            VStack(spacing: 0) {
                topBar
                    .padding(.horizontal, 20)
                    .padding(.top, 8)

                transcriptCard
                    .padding(.horizontal, 20)
                    .padding(.top, 18)
                    .frame(maxHeight: .infinity)

                waveform
                    .padding(.horizontal, 36)
                    .padding(.top, 14)

                micCluster
                    .padding(.top, 18)

                bottomActions
                    .padding(.horizontal, 20)
                    .padding(.top, 20)
                    .padding(.bottom, 16)
            }
        }
        .onAppear { startRecording() }
        .onDisappear {
            invalidateMeterTimer()
            stopRecording(skipTranscription: true)
        }
        .onReceive(transcriber.$transcript) { newValue in
            // Mirror live partials into the editable transcript. After stop()
            // SFSpeech may emit one final result (~200ms); we accept that
            // overwrite, then no more updates fire.
            if !newValue.isEmpty {
                transcription = newValue
            }
        }
    }

    // MARK: - Subviews

    private var backgroundLayer: some View {
        LinearGradient(
            colors: [
                Color(.systemBackground),
                AppColors.calorie.opacity(0.07),
                Color(.systemBackground),
            ],
            startPoint: .top,
            endPoint: .bottom
        )
    }

    private var topBar: some View {
        HStack(alignment: .center) {
            Button {
                UIImpactFeedbackGenerator(style: .light).impactOccurred()
                stopRecording(skipTranscription: true)
                onCancel()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 14, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 34, height: 34)
                    .background(Circle().fill(.ultraThinMaterial))
            }
            .accessibilityLabel("Close")

            Spacer()

            statusPill
        }
    }

    private var statusPill: some View {
        HStack(spacing: 8) {
            if isPreparing {
                ProgressView()
                    .controlSize(.mini)
                    .tint(.secondary)
            } else if isRecording {
                Circle()
                    .fill(Color.red)
                    .frame(width: 8, height: 8)
                    .opacity(dotOpacity)
            } else if !transcription.isEmpty {
                Image(systemName: "checkmark.circle.fill")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundStyle(AppColors.calorie)
            } else {
                Image(systemName: "mic.slash")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(.secondary)
            }
            Text(statusLabel)
                .font(.system(.footnote, design: .rounded).monospacedDigit())
                .fontWeight(.semibold)
                .foregroundStyle(.secondary)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(.ultraThinMaterial))
        .accessibilityLabel(statusAccessibilityLabel)
    }

    private var statusLabel: String {
        if isPreparing { return "Setting up…" }
        if isRecording { return "Recording  \(elapsedLabel)" }
        if !transcription.isEmpty { return "Ready" }
        return "Idle"
    }

    private var statusAccessibilityLabel: String {
        if isPreparing { return "Setting up microphone" }
        if isRecording { return "Recording, \(elapsedLabel) elapsed" }
        return "Stopped"
    }

    private var transcriptCard: some View {
        ZStack(alignment: .topLeading) {
            RoundedRectangle(cornerRadius: 24, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 24, style: .continuous)
                        .strokeBorder(AppColors.calorie.opacity(0.20), lineWidth: 1)
                )
                .shadow(color: AppColors.calorie.opacity(0.07), radius: 18, x: 0, y: 8)

            Group {
                if isPreparing {
                    VStack(alignment: .leading, spacing: 12) {
                        HStack(spacing: 10) {
                            ProgressView()
                                .controlSize(.small)
                                .tint(AppColors.calorie)
                            Text("Setting up microphone…")
                                .font(.system(.title3, design: .rounded, weight: .semibold))
                                .foregroundStyle(.primary)
                        }
                        Text("This takes a moment the first time.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                } else if transcription.isEmpty {
                    VStack(alignment: .leading, spacing: 10) {
                        Text(isRecording ? "Listening…" : "Tap the mic to start")
                            .font(.system(.title2, design: .rounded, weight: .bold))
                            .foregroundStyle(.primary)
                        Text(isRecording
                             ? "Describe what you ate. We'll stop when you do."
                             : "Tell us what you ate — meals, drinks, snacks.")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 0)
                    }
                    .padding(22)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                } else {
                    TextEditor(text: $transcription)
                        .font(.system(.title3))
                        .scrollContentBackground(.hidden)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 14)
                        .accessibilityLabel("Transcription")
                }
            }

            if let error = permissionError {
                VStack {
                    Spacer()
                    HStack(alignment: .top, spacing: 8) {
                        Image(systemName: "exclamationmark.triangle.fill")
                            .font(.caption)
                        Text(error)
                            .font(.caption)
                            .multilineTextAlignment(.leading)
                    }
                    .foregroundStyle(.red)
                    .padding(.horizontal, 16)
                    .padding(.bottom, 12)
                }
            }
        }
        .animation(.easeInOut(duration: 0.2), value: transcription.isEmpty)
        .animation(.easeInOut(duration: 0.2), value: isPreparing)
    }

    private var waveform: some View {
        WaveformStrip(samples: samples)
            .frame(height: 52)
            .opacity(isRecording ? 1.0 : 0.0)
            .animation(.easeInOut(duration: 0.25), value: isRecording)
    }

    private var micCluster: some View {
        VStack(spacing: 10) {
            micButton

            Text(isRecording ? "Auto-stops when you go quiet" : "")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .frame(height: 16)
                .opacity(isRecording ? 1.0 : 0.0)
                .animation(.easeInOut(duration: 0.25), value: isRecording)
        }
    }

    private var micButton: some View {
        ZStack {
            if isRecording {
                Circle()
                    .stroke(AppColors.calorie.opacity(0.5), lineWidth: 2)
                    .frame(width: 116, height: 116)
                    .scaleEffect(pulseScale)
                    .opacity(pulseOpacity)
            }

            Button {
                if isRecording {
                    UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                    stopRecording()
                } else {
                    UIImpactFeedbackGenerator(style: .light).impactOccurred()
                    startRecording()
                }
            } label: {
                ZStack {
                    Circle().fill(
                        LinearGradient(
                            colors: AppColors.calorieGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: 84, height: 84)

                    if isPreparing {
                        ProgressView()
                            .controlSize(.large)
                            .tint(.white)
                    } else {
                        Image(systemName: isRecording ? "stop.fill" : "mic.fill")
                            .font(.system(size: 30, weight: .semibold))
                            .foregroundStyle(.white)
                    }
                }
                .frame(width: 84, height: 84)
                .shadow(color: AppColors.calorie.opacity(isRecording ? 0.55 : 0.35), radius: 22, x: 0, y: 10)
                .opacity(isPreparing ? 0.85 : 1.0)
            }
            .disabled(isPreparing)
            .accessibilityLabel(isPreparing ? "Setting up microphone" : (isRecording ? "Stop recording" : "Start recording"))
            .accessibilityHint("Transcribes your voice on-device for meal logging.")
        }
        .onChange(of: isRecording) { _, recording in
            if recording {
                pulseScale = 1.0
                pulseOpacity = 0.7
                withAnimation(.easeOut(duration: 1.4).repeatForever(autoreverses: false)) {
                    pulseScale = 1.55
                    pulseOpacity = 0.0
                }
                dotOpacity = 1.0
                withAnimation(.easeInOut(duration: 0.7).repeatForever(autoreverses: true)) {
                    dotOpacity = 0.25
                }
            } else {
                withAnimation(.easeInOut(duration: 0.2)) {
                    pulseScale = 1.0
                    pulseOpacity = 0.6
                    dotOpacity = 1.0
                }
            }
        }
    }

    private var bottomActions: some View {
        Group {
            if !isRecording && !transcription.isEmpty {
                HStack(spacing: 12) {
                    Button {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        transcription = ""
                        permissionError = nil
                        startRecording()
                    } label: {
                        HStack(spacing: 6) {
                            Image(systemName: "arrow.counterclockwise")
                                .font(.system(size: 13, weight: .semibold))
                            Text("Re-record")
                                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        }
                        .foregroundStyle(.primary)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .fill(.ultraThinMaterial)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                                        .strokeBorder(Color.secondary.opacity(0.20), lineWidth: 1)
                                )
                        )
                    }

                    Button {
                        UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                        onSubmit(transcription)
                    } label: {
                        HStack(spacing: 8) {
                            Text("Analyze")
                                .font(.system(.headline, design: .rounded, weight: .semibold))
                            Image(systemName: "arrow.right")
                                .font(.system(size: 14, weight: .bold))
                        }
                        .foregroundStyle(.white)
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
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
                        .shadow(color: AppColors.calorie.opacity(analyzeDisabled ? 0.0 : 0.35), radius: 14, x: 0, y: 6)
                        .opacity(analyzeDisabled ? 0.45 : 1.0)
                    }
                    .disabled(analyzeDisabled)
                }
                .transition(.opacity.combined(with: .move(edge: .bottom)))
            } else {
                Color.clear.frame(height: 54)
            }
        }
        .animation(.easeInOut(duration: 0.25), value: transcription.isEmpty)
        .animation(.easeInOut(duration: 0.25), value: isRecording)
    }

    // MARK: - Recording

    private func startRecording() {
        permissionError = nil
        transcription = ""
        elapsed = 0
        hasDetectedSpeech = false
        silenceAccumulated = 0
        samples = Array(repeating: 0, count: VoiceInputView.sampleCount)
        isPreparing = true

        Task {
            // Yield a frame so SwiftUI commits the `isPreparing` state before
            // the (synchronous, main-actor) audio engine bring-up blocks the
            // run loop — otherwise the spinner never appears on first launch.
            try? await Task.sleep(for: .milliseconds(16))
            await transcriber.start(languageCode: Locale.autoupdatingCurrent.language.languageCode?.identifier.lowercased())
            isPreparing = false
            if let error = transcriber.error {
                UINotificationFeedbackGenerator().notificationOccurred(.error)
                permissionError = error.errorDescription
                return
            }
            isRecording = true
            startMeterTimer()
            startRecordingLimit()
        }
    }

    private func stopRecording(skipTranscription: Bool = false) {
        guard isRecording else {
            if skipTranscription { transcriber.stop() }
            return
        }
        recordingLimitTask?.cancel()
        recordingLimitTask = nil
        invalidateMeterTimer()
        transcriber.stop()
        isRecording = false

        if skipTranscription {
            transcription = ""
            return
        }

        let hasText = !transcription.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
        if hasText {
            UINotificationFeedbackGenerator().notificationOccurred(.success)
        } else if let error = transcriber.error {
            UINotificationFeedbackGenerator().notificationOccurred(.error)
            permissionError = error.errorDescription
        }
    }

    private func startMeterTimer() {
        invalidateMeterTimer()
        let tick: TimeInterval = 0.05
        let timer = Timer.scheduledTimer(withTimeInterval: tick, repeats: true) { _ in
            guard isRecording else { return }
            let db = transcriber.currentDb()
            let normalized = normalizedPower(db: db)
            var next = samples
            next.removeFirst()
            next.append(CGFloat(normalized))
            samples = next

            elapsed = min(elapsed + tick, maxRecordingSeconds)

            // Voice-activity auto-stop: once the user has clearly spoken,
            // accumulate continuous silence and end the take when it crosses
            // the threshold. Brief pauses mid-sentence reset the counter.
            if db.isFinite {
                if db >= speechActivationDb {
                    hasDetectedSpeech = true
                    silenceAccumulated = 0
                } else if hasDetectedSpeech && db <= silenceThresholdDb {
                    silenceAccumulated += tick
                    if elapsed >= minRecordingBeforeAutoStop,
                       silenceAccumulated >= silenceAutoStopSeconds {
                        UIImpactFeedbackGenerator(style: .light).impactOccurred()
                        stopRecording()
                    }
                } else {
                    silenceAccumulated = 0
                }
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
        // dBFS roughly [-160, 0]. Treat anything below -55 as silence so the
        // noise floor doesn't visually fill the bars.
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
                UIImpactFeedbackGenerator(style: .medium).impactOccurred()
                stopRecording()
            }
        }
    }
}

// MARK: - Waveform

private struct WaveformStrip: View {
    let samples: [CGFloat]

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
