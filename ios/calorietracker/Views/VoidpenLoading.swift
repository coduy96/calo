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

    @State private var arcRotation: Double = 0
    @State private var subIndex: Int = 0
    @State private var subTimer: Timer?

    private let photoSize: CGFloat = 150
    private let arcSize: CGFloat = 188

    /// The food photo cropped to the camera's focus-frame square (what the user
    /// framed), shown in the circle. Cheap for camera photos (already upright →
    /// CGImage crop is lazy). `nil` for non-photo flows (label / text / voice).
    private var thumbnail: UIImage? {
        image.map { CameraPreviewCrop.focusSquareImage($0, screenSize: UIScreen.main.bounds.size) }
    }

    var body: some View {
        VStack(spacing: 30) {
            Spacer(minLength: 0)

            ZStack {
                // Faint full track so the comet reads as moving along a path.
                Circle()
                    .stroke(Color.primary.opacity(0.06), lineWidth: 3.5)
                    .frame(width: arcSize, height: arcSize)

                // Single sweeping arc — a comet that orbits the photo.
                Circle()
                    .trim(from: 0, to: 0.25)
                    .stroke(
                        AngularGradient(
                            gradient: Gradient(stops: [
                                .init(color: AppColors.calorie.opacity(0.0), location: 0.0),
                                .init(color: AppColors.calorie, location: 0.25),
                            ]),
                            center: .center
                        ),
                        style: StrokeStyle(lineWidth: 3.5, lineCap: .round)
                    )
                    .frame(width: arcSize, height: arcSize)
                    .rotationEffect(.degrees(arcRotation))

                // Center: circular focus-frame photo, or icon for non-photo flows.
                Group {
                    if let thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                            .frame(width: photoSize, height: photoSize)
                            .clipShape(Circle())
                            .overlay(Circle().stroke(Color.white.opacity(0.14), lineWidth: 0.7))
                    } else {
                        ZStack {
                            Circle().fill(AppColors.calorie.opacity(0.10))
                            Image(systemName: systemIcon)
                                .font(.system(size: 52, weight: .light))
                                .foregroundStyle(
                                    LinearGradient(colors: AppColors.calorieGradient,
                                                   startPoint: .topLeading, endPoint: .bottomTrailing)
                                )
                        }
                        .frame(width: photoSize, height: photoSize)
                    }
                }
                .shadow(color: .black.opacity(0.12), radius: 14, x: 0, y: 6)
            }
            .frame(width: arcSize, height: arcSize)

            VStack(spacing: 8) {
                Text(message)
                    .font(.system(.title3, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)

                ZStack {
                    if !subMessages.isEmpty {
                        Text(subMessages[subIndex])
                            .font(.system(.subheadline, design: .rounded))
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
            }

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
            withAnimation(.linear(duration: 1.1).repeatForever(autoreverses: false)) {
                arcRotation = 360
            }
            startSubRotation()
        }
        .onDisappear {
            subTimer?.invalidate()
            subTimer = nil
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
