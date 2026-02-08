import SwiftUI

struct SpinWheelView: View {
    let onComplete: (Int) -> Void

    @State private var rotation: Double = 0
    @State private var hasSpun = false
    @State private var showResult = false
    @State private var resultDiscount = 0

    // 8 segments: [10%, 15%, 20%, 10%, 15%, 20%, 25%, 27%]
    private let segments: [(Int, Color)] = [
        (10, Color(hex: 0xFF6B8A)),
        (15, Color(hex: 0x30D158)),
        (20, Color(hex: 0xFF9F0A)),
        (10, Color(hex: 0x0A84FF)),
        (15, Color(hex: 0xFF375F)),
        (20, Color(hex: 0x5AC8FA)),
        (25, Color(hex: 0x6EE7B7)),
        (27, Color(hex: 0xFFD700))
    ]

    private let segmentAngle: Double = 360.0 / 8.0 // 45 degrees each

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            VStack(spacing: 16) {
                Text(showResult ? "Congratulations!" : "Spin for a\nspecial discount!")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                if showResult {
                    Text("You got **\(resultDiscount)% off** your yearly plan!")
                        .font(.system(.callout, design: .rounded))
                        .foregroundStyle(.secondary)
                        .multilineTextAlignment(.center)
                } else {
                    Text("Try your luck and save on Premium")
                        .font(.system(.callout, design: .rounded))
                        .foregroundStyle(.secondary)
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Pointer
            Image(systemName: "arrowtriangle.down.fill")
                .font(.system(size: 24))
                .foregroundStyle(Color.primary)
                .padding(.bottom, 4)

            // Wheel
            ZStack {
                ForEach(0..<segments.count, id: \.self) { index in
                    WheelSegment(
                        startAngle: Double(index) * segmentAngle,
                        endAngle: Double(index + 1) * segmentAngle,
                        color: segments[index].1,
                        text: "\(segments[index].0)%",
                        isHighlighted: segments[index].0 == 27
                    )
                }

                Circle()
                    .fill(Color(.systemBackground))
                    .frame(width: 50, height: 50)
                    .shadow(color: .black.opacity(0.1), radius: 4)

                Image(systemName: "gift.fill")
                    .font(.system(size: 20))
                    .foregroundStyle(AppColors.calorie)
            }
            .frame(width: 280, height: 280)
            .rotationEffect(.degrees(rotation))
            .padding(.vertical, 20)

            Spacer()

            if showResult {
                Button {
                    onComplete(resultDiscount)
                } label: {
                    Text("Claim My Discount")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color(.systemBackground))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(Color.primary, in: Capsule())
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
            } else {
                Button {
                    spin()
                } label: {
                    Text("Spin the Wheel!")
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(Color(.systemBackground))
                        .frame(maxWidth: .infinity)
                        .frame(height: 54)
                        .background(
                            LinearGradient(colors: AppColors.calorieGradient, startPoint: .leading, endPoint: .trailing),
                            in: Capsule()
                        )
                }
                .padding(.horizontal, 24)
                .padding(.bottom, 36)
                .disabled(hasSpun)
            }
        }
    }

    private func spin() {
        guard !hasSpun else { return }
        hasSpun = true

        // The 27% segment is index 7 (last segment)
        // It spans from 315 degrees to 360 degrees
        // The pointer is at the top (0/360 degrees)
        // We need the wheel to rotate so that segment 7's center aligns with the top
        // Segment 7 center = 337.5 degrees from start
        // We rotate clockwise, so we need: 360 - 337.5 = 22.5 degrees offset
        // Plus multiple full rotations for effect
        let fullRotations = 5.0 * 360.0
        let targetOffset = 360.0 - (7.0 * segmentAngle + segmentAngle / 2.0) // Land on center of segment 7
        let totalRotation = fullRotations + targetOffset

        withAnimation(.interpolatingSpring(stiffness: 15, damping: 12).speed(0.3)) {
            rotation = totalRotation
        }

        // Show result after animation
        DispatchQueue.main.asyncAfter(deadline: .now() + 3.5) {
            resultDiscount = 27
            withAnimation(.spring(response: 0.5)) {
                showResult = true
            }
        }
    }
}

struct WheelSegment: View {
    let startAngle: Double
    let endAngle: Double
    let color: Color
    let text: String
    let isHighlighted: Bool

    var body: some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2

            ZStack {
                Path { path in
                    path.move(to: center)
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(startAngle - 90),
                        endAngle: .degrees(endAngle - 90),
                        clockwise: false
                    )
                    path.closeSubpath()
                }
                .fill(color.opacity(isHighlighted ? 1.0 : 0.8))

                Path { path in
                    path.move(to: center)
                    path.addArc(
                        center: center,
                        radius: radius,
                        startAngle: .degrees(startAngle - 90),
                        endAngle: .degrees(endAngle - 90),
                        clockwise: false
                    )
                    path.closeSubpath()
                }
                .stroke(Color.white, lineWidth: 2)

                // Text label
                let midAngle = (startAngle + endAngle) / 2.0 - 90
                let textRadius = radius * 0.65
                let x = center.x + textRadius * cos(midAngle * .pi / 180)
                let y = center.y + textRadius * sin(midAngle * .pi / 180)

                Text(text)
                    .font(.system(size: isHighlighted ? 14 : 12, weight: .bold, design: .rounded))
                    .foregroundStyle(.white)
                    .shadow(color: .black.opacity(0.3), radius: 1)
                    .position(x: x, y: y)
                    .rotationEffect(.degrees(midAngle + 90))
            }
        }
    }
}
