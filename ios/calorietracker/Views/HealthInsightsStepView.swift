import SwiftUI

struct HealthInsightsStepView: View {
    let insights: HealthInsights
    let onContinue: () -> Void

    @State private var revealedCount = 0

    private let stagger: Double = 0.18
    private let initialDelay: Double = 0.25

    private var totalReveals: Int { insights.cards.count + 1 } // cards + advice
    private var revealComplete: Bool { revealedCount >= totalReveals }

    var body: some View {
        VStack(spacing: 0) {
            header

            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ForEach(Array(insights.cards.enumerated()), id: \.element.id) { idx, card in
                        insightCardView(card)
                            .opacity(idx < revealedCount ? 1 : 0)
                            .offset(y: idx < revealedCount ? 0 : 12)
                            .animation(.spring(response: 0.45, dampingFraction: 0.82), value: revealedCount)
                    }

                    adviceCardView(insights.primaryAdvice)
                        .opacity(revealedCount >= totalReveals ? 1 : 0)
                        .offset(y: revealedCount >= totalReveals ? 0 : 12)
                        .animation(.spring(response: 0.45, dampingFraction: 0.82), value: revealedCount)
                }
                .padding(.horizontal, 24)
                .padding(.top, 16)
                .padding(.bottom, 24)
            }

            continueButton
        }
        .onAppear(perform: startReveal)
    }

    // MARK: - Header

    private var header: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Here's your baseline")
                .font(.system(size: 28, weight: .bold, design: .rounded))
            Text("The numbers — straight, no spin.")
                .font(.system(.callout, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.horizontal, 24)
        .padding(.top, 24)
    }

    // MARK: - Insight card

    private func insightCardView(_ card: HealthInsights.Card) -> some View {
        let iconColor: Color = {
            switch card.tone {
            case .positive: return AppColors.calorie
            case .caution: return .orange
            case .neutral: return .secondary
            }
        }()

        return HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(iconColor.opacity(0.12))
                    .frame(width: 44, height: 44)
                Image(systemName: card.icon)
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(iconColor)
            }

            VStack(alignment: .leading, spacing: 6) {
                HStack(alignment: .firstTextBaseline) {
                    Text(card.title)
                        .font(.system(.caption, design: .rounded, weight: .medium))
                        .foregroundStyle(.secondary)
                    Spacer(minLength: 8)
                    Text(card.value)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)
                }
                Text(card.interpretation)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.primary.opacity(0.85))
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.appCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(card.tone == .caution ? Color.orange.opacity(0.4) : Color.clear, lineWidth: 1)
        )
    }

    // MARK: - Advice card

    private func adviceCardView(_ advice: String) -> some View {
        HStack(alignment: .top, spacing: 14) {
            ZStack {
                Circle()
                    .fill(
                        LinearGradient(colors: AppColors.calorieGradient,
                                       startPoint: .topLeading,
                                       endPoint: .bottomTrailing)
                    )
                    .frame(width: 44, height: 44)
                Image(systemName: "sparkles")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundStyle(.white)
            }

            VStack(alignment: .leading, spacing: 6) {
                Text("Your one job")
                    .font(.system(.caption, design: .rounded, weight: .semibold))
                    .foregroundStyle(AppColors.calorie)
                    .textCase(.uppercase)
                Text(advice)
                    .font(.system(.body, design: .rounded, weight: .medium))
                    .foregroundStyle(.primary)
                    .fixedSize(horizontal: false, vertical: true)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            LinearGradient(colors: [AppColors.calorie.opacity(0.08), AppColors.calorie.opacity(0.02)],
                           startPoint: .topLeading,
                           endPoint: .bottomTrailing),
            in: RoundedRectangle(cornerRadius: 18, style: .continuous)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .strokeBorder(AppColors.calorie.opacity(0.25), lineWidth: 1)
        )
    }

    // MARK: - Continue button

    private var continueButton: some View {
        Button(action: onContinue) {
            Text("Looks right")
                .font(.system(.body, design: .rounded, weight: .semibold))
                .foregroundStyle(.white)
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(
                    LinearGradient(colors: AppColors.calorieGradient, startPoint: .leading, endPoint: .trailing),
                    in: RoundedRectangle(cornerRadius: 16, style: .continuous)
                )
                .shadow(color: AppColors.calorie.opacity(0.3), radius: 8, y: 4)
        }
        .padding(.horizontal, 24)
        .padding(.bottom, 36)
        .opacity(revealComplete ? 1 : 0.4)
        .disabled(!revealComplete)
        .animation(.snappy, value: revealComplete)
    }

    // MARK: - Reveal

    private func startReveal() {
        guard revealedCount == 0 else { return }
        let haptic = UIImpactFeedbackGenerator(style: .light)
        haptic.prepare()
        for i in 0..<totalReveals {
            DispatchQueue.main.asyncAfter(deadline: .now() + initialDelay + Double(i) * stagger) {
                revealedCount = i + 1
                haptic.impactOccurred(intensity: 0.55)
            }
        }
    }
}
