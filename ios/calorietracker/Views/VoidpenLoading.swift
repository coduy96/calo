import SwiftUI

enum VoidpenLoadingDotSize {
    case small
    case medium

    var diameter: CGFloat {
        switch self {
        case .small:  return 7
        case .medium: return 10
        }
    }

    var spacing: CGFloat {
        switch self {
        case .small:  return 5
        case .medium: return 8
        }
    }

    var step: Double {
        switch self {
        case .small:  return 0.35
        case .medium: return 0.42
        }
    }
}

struct VoidpenLoadingDots: View {
    var size: VoidpenLoadingDotSize = .medium

    @State private var phase = 0
    @State private var timer: Timer?

    var body: some View {
        HStack(spacing: size.spacing) {
            ForEach(0..<3, id: \.self) { i in
                Circle()
                    .fill(
                        LinearGradient(
                            colors: AppColors.calorieGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .frame(width: size.diameter, height: size.diameter)
                    .opacity(phase == i ? 1.0 : 0.3)
                    .scaleEffect(phase == i ? 1.2 : 1.0)
                    .animation(.easeInOut(duration: size.step), value: phase)
            }
        }
        .onAppear {
            timer?.invalidate()
            timer = Timer.scheduledTimer(withTimeInterval: size.step, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
        }
        .onDisappear {
            timer?.invalidate()
            timer = nil
        }
    }
}

struct VoidpenLoadingCompact: View {
    var size: VoidpenLoadingDotSize = .small
    var label: Text?

    init(size: VoidpenLoadingDotSize = .small, label: Text? = nil) {
        self.size = size
        self.label = label
    }

    init(_ key: LocalizedStringKey, size: VoidpenLoadingDotSize = .small) {
        self.size = size
        self.label = Text(key)
    }

    var body: some View {
        HStack(spacing: 10) {
            VoidpenLoadingDots(size: size)
            if let label {
                label
                    .font(.footnote)
                    .foregroundStyle(.secondary)
            }
        }
    }
}

struct VoidpenLoadingHero: View {
    let image: UIImage?
    var systemIcon: String = "text.magnifyingglass"
    var message: LocalizedStringKey
    var subMessages: [LocalizedStringKey] = []
    var onCancel: (() -> Void)? = nil

    @State private var rotationOuter: Double = 0
    @State private var rotationInner: Double = 0
    @State private var haloScale: CGFloat = 1.0
    @State private var haloOpacity: Double = 0.55
    @State private var iconBreath: CGFloat = 1.0
    @State private var subIndex: Int = 0
    @State private var subTimer: Timer?

    private let frameSize: CGFloat = 320
    private let imageSize: CGFloat = 210
    private let iconCardSize: CGFloat = 170
    private let outerRingSize: CGFloat = 280
    private let innerRingSize: CGFloat = 248

    var body: some View {
        VStack(spacing: 28) {
            Spacer(minLength: 0)

            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [AppColors.calorie.opacity(0.24), .clear],
                            center: .center,
                            startRadius: 0,
                            endRadius: 175
                        )
                    )
                    .frame(width: frameSize + 40, height: frameSize + 40)
                    .scaleEffect(haloScale)
                    .opacity(haloOpacity)

                Circle()
                    .trim(from: 0, to: 0.72)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(stops: [
                                .init(color: AppColors.calorie.opacity(0.0), location: 0.0),
                                .init(color: (AppColors.calorieGradient.last ?? AppColors.calorie).opacity(0.55), location: 0.55),
                                .init(color: AppColors.calorieGradient.first ?? AppColors.calorie, location: 1.0),
                            ]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 4, lineCap: .round)
                    )
                    .frame(width: outerRingSize, height: outerRingSize)
                    .rotationEffect(.degrees(rotationOuter))
                    .shadow(color: AppColors.calorie.opacity(0.35), radius: 6, x: 0, y: 0)

                Circle()
                    .trim(from: 0, to: 0.30)
                    .stroke(
                        LinearGradient(
                            colors: AppColors.calorieGradient,
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        ),
                        style: StrokeStyle(lineWidth: 2.5, lineCap: .round)
                    )
                    .frame(width: innerRingSize, height: innerRingSize)
                    .rotationEffect(.degrees(rotationInner))

                if let image {
                    // Match the Review Food image: full photo, scaled to fit,
                    // rounded rectangle (no crop, no circle) — consistent end-to-end.
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .frame(maxWidth: imageSize, maxHeight: imageSize)
                        .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
                        .overlay(
                            RoundedRectangle(cornerRadius: 16, style: .continuous)
                                .stroke(Color.white.opacity(0.25), lineWidth: 0.7)
                        )
                        .shadow(color: AppColors.calorie.opacity(0.32), radius: 20, x: 0, y: 12)
                        .scaleEffect(iconBreath)
                } else {
                    ZStack {
                        Circle()
                            .fill(AppColors.calorie.opacity(0.12))
                            .frame(width: iconCardSize, height: iconCardSize)
                            .overlay(
                                Circle()
                                    .stroke(
                                        LinearGradient(
                                            colors: AppColors.calorieGradient,
                                            startPoint: .topLeading,
                                            endPoint: .bottomTrailing
                                        ).opacity(0.4),
                                        lineWidth: 1
                                    )
                            )
                            .shadow(color: AppColors.calorie.opacity(0.26), radius: 18, x: 0, y: 10)

                        Image(systemName: systemIcon)
                            .font(.system(size: 64, weight: .light))
                            .foregroundStyle(
                                LinearGradient(
                                    colors: AppColors.calorieGradient,
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                    }
                    .scaleEffect(iconBreath)
                }
            }
            .frame(width: frameSize, height: frameSize)

            Text(message)
                .font(.system(.title3, design: .rounded, weight: .semibold))
                .foregroundStyle(AppColors.calorie)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 24)

            ZStack {
                if !subMessages.isEmpty {
                    Text(subMessages[subIndex])
                        .font(.system(.footnote, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                        .id(subIndex)
                        .transition(
                            .asymmetric(
                                insertion: .opacity.combined(with: .move(edge: .bottom)),
                                removal: .opacity.combined(with: .move(edge: .top))
                            )
                        )
                }
            }
            .frame(height: 22)

            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(.background)
        .overlay(alignment: .topLeading) {
            if let onCancel {
                Button(action: onCancel) {
                    Image(systemName: "xmark")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundStyle(.secondary)
                        .frame(width: 38, height: 38)
                        .background(.ultraThinMaterial, in: Circle())
                        .overlay(Circle().stroke(Color.primary.opacity(0.08), lineWidth: 0.5))
                }
                .padding(.top, 14)
                .padding(.leading, 16)
                .accessibilityLabel("Cancel")
            }
        }
        .onAppear {
            startRotation()
            startHalo()
            startBreath()
            startSubRotation()
        }
        .onDisappear {
            subTimer?.invalidate()
            subTimer = nil
        }
    }

    private func startRotation() {
        withAnimation(.linear(duration: 2.4).repeatForever(autoreverses: false)) {
            rotationOuter = 360
        }
        withAnimation(.linear(duration: 3.6).repeatForever(autoreverses: false)) {
            rotationInner = -360
        }
    }

    private func startHalo() {
        withAnimation(.easeInOut(duration: 1.8).repeatForever(autoreverses: true)) {
            haloScale = 1.06
            haloOpacity = 0.9
        }
    }

    private func startBreath() {
        withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) {
            iconBreath = 1.03
        }
    }

    private func startSubRotation() {
        guard subMessages.count > 1 else { return }
        subTimer?.invalidate()
        subTimer = Timer.scheduledTimer(withTimeInterval: 2.4, repeats: true) { _ in
            withAnimation(.easeInOut(duration: 0.45)) {
                subIndex = (subIndex + 1) % subMessages.count
            }
        }
    }
}
