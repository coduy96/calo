import SwiftUI

struct AddFoodPromptOverlay: View {
    let onDismiss: () -> Void
    @Environment(\.accessibilityReduceMotion) private var reduceMotion
    @State private var isLifted = false

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            iconBadge

            VStack(alignment: .leading, spacing: 4) {
                Text("Log your first meal")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
                Text("Tap the + button to add what you've eaten today.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineSpacing(1)
                    .fixedSize(horizontal: false, vertical: true)
            }
            .padding(.top, 1)

            Button {
                onDismiss()
            } label: {
                Image(systemName: "xmark")
                    .font(.system(size: 10, weight: .bold))
                    .foregroundStyle(.secondary)
                    .frame(width: 24, height: 24)
                    .background(Circle().fill(Color.primary.opacity(0.06)))
            }
            .buttonStyle(.plain)
            .accessibilityLabel(Text("Dismiss"))
        }
        .padding(.leading, 12)
        .padding(.trailing, 10)
        .padding(.vertical, 12)
        .padding(.bottom, AddFoodPromptCallout.pointerHeight)
        .frame(maxWidth: 286)
        // Same glass chrome the tab/navigation bar uses, clipped to the callout shape
        // (tail included) so the prompt reads as part of that chrome rather than an
        // opaque card floating over it.
        .modifier(CalloutGlassBackground())
        .fixedSize(horizontal: false, vertical: true)
        .offset(y: reduceMotion ? 0 : (isLifted ? -2 : 0))
        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isLifted)
        .onAppear {
            guard !reduceMotion else { return }
            isLifted = true
        }
        .accessibilityElement(children: .combine)
        .accessibilityLabel(Text("Log your first meal"))
        .accessibilityHint(Text("Tap the plus button below to add a meal"))
    }

    private var iconBadge: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: AppColors.calorieGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: "fork.knife")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(.white)
        }
        .frame(width: 32, height: 32)
        .shadow(color: AppColors.calorie.opacity(0.3), radius: 4, y: 2)
        .scaleEffect(reduceMotion ? 1 : (isLifted ? 1.04 : 1))
        .animation(.easeInOut(duration: 2.0).repeatForever(autoreverses: true), value: isLifted)
    }
}

/// Applies the same glass chrome as the tab/navigation bar to the callout silhouette.
/// On iOS 26+ this is the system Liquid Glass material; on earlier releases it falls
/// back to the app's standard `.ultraThinMaterial` + hairline-stroke glass so the
/// prompt stays consistent with the navigation chrome of whichever OS it runs on.
private struct CalloutGlassBackground: ViewModifier {
    func body(content: Content) -> some View {
        if #available(iOS 26.0, *) {
            content.glassEffect(.regular, in: AddFoodPromptCallout())
        } else {
            content
                .background(
                    AddFoodPromptCallout()
                        .fill(.ultraThinMaterial)
                        .shadow(color: .black.opacity(0.12), radius: 10, x: 0, y: 5)
                        .shadow(color: .black.opacity(0.06), radius: 3, x: 0, y: 1)
                )
                .overlay(
                    AddFoodPromptCallout()
                        .stroke(Color.white.opacity(0.15), lineWidth: 0.5)
                )
        }
    }
}

/// Rounded-rectangle callout with a soft curved tail at the bottom-right, aligned
/// to sit just above the floating "+" Add Food button. The pointer uses quadratic
/// curves on both sides for a smoother, more organic shape than a sharp triangle.
struct AddFoodPromptCallout: Shape {
    static let pointerHeight: CGFloat = 10
    static let pointerWidth: CGFloat = 18
    /// Distance from the shape's right edge to the pointer's tip.
    static let pointerInsetFromRight: CGFloat = 24
    static let cornerRadius: CGFloat = 16

    func path(in rect: CGRect) -> Path {
        let r = Self.cornerRadius
        let ph = Self.pointerHeight
        let pw = Self.pointerWidth
        let pInset = Self.pointerInsetFromRight

        let bubbleBottom = rect.maxY - ph
        let tipX = rect.maxX - pInset
        let pointerLeftX = tipX - pw / 2
        let pointerRightX = tipX + pw / 2

        var path = Path()
        path.move(to: CGPoint(x: rect.minX + r, y: rect.minY))
        path.addLine(to: CGPoint(x: rect.maxX - r, y: rect.minY))
        path.addArc(
            center: CGPoint(x: rect.maxX - r, y: rect.minY + r),
            radius: r,
            startAngle: .degrees(-90), endAngle: .degrees(0), clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.maxX, y: bubbleBottom - r))
        path.addArc(
            center: CGPoint(x: rect.maxX - r, y: bubbleBottom - r),
            radius: r,
            startAngle: .degrees(0), endAngle: .degrees(90), clockwise: false
        )
        path.addLine(to: CGPoint(x: pointerRightX, y: bubbleBottom))
        // Smooth curved right side of pointer, slightly bulging out, into a soft tip.
        path.addQuadCurve(
            to: CGPoint(x: tipX, y: rect.maxY),
            control: CGPoint(x: tipX + 2, y: bubbleBottom + ph * 0.55)
        )
        // Smooth curved left side of pointer, mirrored, back up to the bubble bottom.
        path.addQuadCurve(
            to: CGPoint(x: pointerLeftX, y: bubbleBottom),
            control: CGPoint(x: tipX - 2, y: bubbleBottom + ph * 0.55)
        )
        path.addLine(to: CGPoint(x: rect.minX + r, y: bubbleBottom))
        path.addArc(
            center: CGPoint(x: rect.minX + r, y: bubbleBottom - r),
            radius: r,
            startAngle: .degrees(90), endAngle: .degrees(180), clockwise: false
        )
        path.addLine(to: CGPoint(x: rect.minX, y: rect.minY + r))
        path.addArc(
            center: CGPoint(x: rect.minX + r, y: rect.minY + r),
            radius: r,
            startAngle: .degrees(180), endAngle: .degrees(270), clockwise: false
        )
        path.closeSubpath()
        return path
    }
}

#Preview {
    ZStack(alignment: .bottomTrailing) {
        Color.gray.opacity(0.2).ignoresSafeArea()
        Circle()
            .fill(.orange)
            .frame(width: 52, height: 52)
            .padding(.trailing, 16)
            .padding(.bottom, 8)
        AddFoodPromptOverlay(onDismiss: {})
            .padding(.trailing, 8)
            .padding(.bottom, 72)
    }
}
