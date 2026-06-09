import SwiftUI

struct InlinePaywallStepView: View {
    let profile: UserProfile
    let insights: HealthInsights
    let isMetric: Bool
    @Binding var hasCompletedOnboarding: Bool

    @Environment(StoreManager.self) private var storeManager
    @State private var selectedProduct: PlusProduct?

    private let termsURL = URL(string: "https://voidpen.com/terms")!
    private let privacyURL = URL(string: "https://voidpen.com/privacy")!

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 22) {
                    personalizedHeader
                    planRecapCard
                    lossSection
                    compactValueAnchor
                    tierCards
                    trustStrip
                    footerLinks
                }
                .padding(.horizontal, 24)
                .padding(.top, 8)
                .padding(.bottom, 24)
            }

            if let error = storeManager.purchaseError {
                Text(error)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }

            VStack(spacing: 10) {
                subscribeButton
                trialFinePrint
            }
            .padding(.horizontal, 24)
            .padding(.bottom, 24)
        }
        .task {
            if storeManager.products.isEmpty {
                await storeManager.loadProducts()
            }
            selectDefaultProductIfNeeded()
        }
        .onChange(of: storeManager.products.map(\.id)) { _, _ in
            selectDefaultProductIfNeeded()
        }
    }

    // MARK: - Header

    private var personalizedHeader: some View {
        VStack(spacing: 14) {
            Image("onboardingLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 100, height: 100)

            Text(headlineCopy)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("Twelve screens to get here. Don't reset the counter.")
                .font(.system(.callout, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(.top, 12)
    }

    private var headlineCopy: String {
        guard profile.goal != .maintain,
              let weeks = insights.weeksToGoal,
              let target = profile.goalWeightKg else {
            return String(localized: "The plan is built. Run it.")
        }
        return String(localized: "\(weeks) weeks to \(weightDisplay(for: target)). Don't bail in the parking lot.")
    }

    // MARK: - Plan recap

    private var planRecapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Your plan")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)

            VStack(spacing: 10) {
                recapRow(
                    icon: "flame.fill",
                    label: String(localized: "Daily target"),
                    value: String(localized: "\(profile.dailyCalories) cal")
                )

                if let weeks = insights.weeksToGoal,
                   let target = profile.goalWeightKg,
                   profile.goal != .maintain {
                    recapRow(
                        icon: "arrow.right.circle.fill",
                        label: String(localized: "Path"),
                        value: String(localized: "\(weeks) weeks → \(weightDisplay(for: target))")
                    )
                }

                if let date = insights.goalDate, profile.goal != .maintain {
                    recapRow(
                        icon: "calendar",
                        label: String(localized: "Reach by"),
                        value: goalDateText(date)
                    )
                }
            }

            Text(insights.primaryAdvice)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(3)
                .fixedSize(horizontal: false, vertical: true)
                .padding(.top, 2)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            HStack(spacing: 0) {
                LinearGradient(colors: AppColors.calorieGradient,
                               startPoint: .top, endPoint: .bottom)
                    .frame(width: 4)
                AppColors.appCard
            }
            .clipShape(RoundedRectangle(cornerRadius: 16, style: .continuous))
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private func recapRow(icon: String, label: String, value: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.calorie)
                .frame(width: 18)
            Text(label)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
            Spacer()
            Text(value)
                .font(.system(.subheadline, design: .rounded, weight: .semibold))
                .foregroundStyle(.primary)
        }
    }

    // MARK: - Loss section

    private var lossSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Walk away and this resets.")
                .font(.system(.headline, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)

            VStack(spacing: 8) {
                ForEach(lossItems, id: \.self) { item in
                    lossRow(item)
                }
            }

            Text("Day one, all over again.")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
                .padding(.top, 2)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var lossItems: [String] {
        var items: [String] = [
            String(localized: "Your \(profile.dailyCalories) cal target, tuned to your TDEE"),
            String(localized: "Coach that already knows your goal, pace, and history"),
            String(localized: "Snap-a-meal and voice logging"),
            String(localized: "Trend forecasts that read your real curve, not daily noise")
        ]
        if let weeks = insights.weeksToGoal,
           let target = profile.goalWeightKg,
           profile.goal != .maintain {
            items.append(String(localized: "The \(weeks)-week path to \(weightDisplay(for: target))"))
        }
        return items
    }

    private func lossRow(_ text: String) -> some View {
        HStack(alignment: .top, spacing: 10) {
            Image(systemName: "xmark.circle.fill")
                .font(.system(size: 16, weight: .semibold))
                .foregroundStyle(.red.opacity(0.85))
                .padding(.top, 1)
            Text(text)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.primary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Compact value anchor

    private var compactValueAnchor: some View {
        HStack(spacing: 8) {
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 14, weight: .semibold))
                .foregroundStyle(AppColors.calorie)
            Text("Cheaper than a single nutritionist visit — for a whole month.")
                .font(.system(.caption, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
            Spacer(minLength: 0)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    // MARK: - Tier cards

    @ViewBuilder
    private var tierCards: some View {
        if storeManager.products.isEmpty {
            VStack(spacing: 12) {
                Text("Couldn't load plans")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.secondary)
                Button {
                    Task { await storeManager.loadProducts() }
                } label: {
                    Text("Try again")
                        .font(.system(.caption, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppColors.calorie)
                        .padding(.horizontal, 14)
                        .padding(.vertical, 8)
                        .background(AppColors.calorie.opacity(0.1), in: Capsule())
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 20)
        } else {
            VStack(spacing: 12) {
                if let yearly = storeManager.yearlyProduct {
                    tierCard(product: yearly, badge: recommendedBadge, isHighlighted: true)
                }
                if let monthly = storeManager.monthlyProduct {
                    tierCard(product: monthly, badge: nil, isHighlighted: false)
                }
                if let weekly = storeManager.weeklyProduct {
                    tierCard(product: weekly, badge: nil, isHighlighted: false)
                }
            }
        }
    }

    private var recommendedBadge: String {
        if let weeks = insights.weeksToGoal, profile.goal != .maintain {
            return String(localized: "Matches your \(weeks)-week plan")
        }
        return String(localized: "Best Value")
    }

    private func tierCard(product: PlusProduct, badge: String?, isHighlighted: Bool) -> some View {
        let isSelected = selectedProduct?.id == product.id
        return Button {
            let haptic = UIImpactFeedbackGenerator(style: .light)
            haptic.impactOccurred()
            withAnimation(.spring(response: 0.3)) { selectedProduct = product }
        } label: {
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    HStack(spacing: 8) {
                        Text(product.title)
                            .font(.system(.body, design: .rounded, weight: .semibold))
                            .foregroundStyle(.primary)
                        if let badge {
                            Text(badge)
                                .font(.system(.caption2, design: .rounded, weight: .bold))
                                .foregroundStyle(.white)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 3)
                                .background(
                                    LinearGradient(colors: AppColors.calorieGradient,
                                                   startPoint: .leading,
                                                   endPoint: .trailing),
                                    in: Capsule()
                                )
                                .lineLimit(1)
                                .minimumScaleFactor(0.85)
                        }
                    }
                    if let intro = product.introOfferCopy {
                        Text(intro)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(AppColors.calorie)
                    } else {
                        Text(product.detail)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                    if let perDay = product.pricePerDayText {
                        Text("Less than \(perDay)/day")
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(AppColors.calorie.opacity(0.9))
                    }
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? AppColors.calorie : Color.secondary.opacity(0.3))
            }
            .padding(.horizontal, 16)
            .padding(.vertical, isHighlighted ? 20 : 16)
            .background(AppColors.appCard, in: RoundedRectangle(cornerRadius: 16))
            .overlay {
                if isSelected {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(AppColors.calorie, lineWidth: 2)
                } else if isHighlighted && selectedProduct == nil {
                    RoundedRectangle(cornerRadius: 16)
                        .strokeBorder(
                            LinearGradient(colors: AppColors.calorieGradient,
                                           startPoint: .leading,
                                           endPoint: .trailing),
                            lineWidth: 1.5
                        )
                }
            }
        }
        .buttonStyle(.plain)
    }

    // MARK: - Trust strip

    private var trustStrip: some View {
        HStack(spacing: 8) {
            trustPill(icon: "arrow.uturn.backward.circle.fill", label: String(localized: "Cancel anytime"))
            trustPill(icon: "gift.fill", label: String(localized: "3 days free"))
        }
    }

    private func trustPill(icon: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(label)
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .lineLimit(1)
                .minimumScaleFactor(0.8)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 10)
        .padding(.vertical, 7)
        .frame(maxWidth: .infinity)
        .background(
            Capsule()
                .fill(AppColors.appCard)
        )
        .overlay(
            Capsule()
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    // MARK: - Subscribe CTA

    private var subscribeButton: some View {
        Button {
            guard let product = selectedProduct else { return }
            Task {
                let success = await storeManager.purchase(product)
                if success {
                    UserDefaults.standard.removeObject(forKey: "onboardingStep")
                    hasCompletedOnboarding = true
                }
            }
        } label: {
            Group {
                if storeManager.isPurchasing {
                    ProgressView().tint(.white)
                } else {
                    Text(subscribeButtonTitle)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                }
            }
            .foregroundStyle(.white)
            .frame(maxWidth: .infinity)
            .frame(height: 54)
            .background(
                LinearGradient(colors: AppColors.calorieGradient,
                               startPoint: .leading,
                               endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .shadow(color: AppColors.calorie.opacity(0.3), radius: 8, y: 4)
        }
        .disabled(selectedProduct == nil || storeManager.isPurchasing)
    }

    private var subscribeButtonTitle: String {
        let hasIntro = selectedProduct?.introOfferCopy != nil
        let weeks = profile.goal != .maintain ? insights.weeksToGoal : nil

        if let weeks {
            return hasIntro
                ? String(localized: "Start My \(weeks)-Week Plan")
                : String(localized: "Lock In My \(weeks)-Week Plan")
        }
        return hasIntro
            ? String(localized: "Start My Plan — 3 Days Free")
            : String(localized: "Lock In My Plan")
    }

    @ViewBuilder
    private var trialFinePrint: some View {
        if let product = selectedProduct {
            Text(trialFinePrintText(for: product))
                .font(.system(.caption2, design: .rounded))
                .foregroundStyle(.primary)
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)
        }
    }

    private func trialFinePrintText(for product: PlusProduct) -> String {
        let period: String
        switch product.id {
        case StoreManager.yearlyID: period = String(localized: "year")
        case StoreManager.monthlyID: period = String(localized: "month")
        case StoreManager.weeklyID: period = String(localized: "week")
        default: period = String(localized: "period")
        }

        if product.introOfferCopy != nil {
            return String(localized: "3 days free, then \(product.displayPrice) per \(period) — $0 if it's not for you. Auto-renews; cancel anytime in 2 taps in Settings.")
        }
        return String(localized: "\(product.displayPrice) per \(period). Auto-renews; cancel anytime in 2 taps in Settings.")
    }

    // MARK: - Footer

    private var footerLinks: some View {
        HStack(spacing: 18) {
            Button {
                Task {
                    let success = await storeManager.restorePurchases()
                    if success {
                        UserDefaults.standard.removeObject(forKey: "onboardingStep")
                        hasCompletedOnboarding = true
                    }
                }
            } label: {
                Text("Restore Purchases")
            }
            Link(String(localized: "Terms"), destination: termsURL)
            Link(String(localized: "Privacy"), destination: privacyURL)
        }
        .font(.system(.footnote, design: .rounded, weight: .medium))
        .foregroundStyle(.secondary)
        .padding(.top, 4)
    }

    // MARK: - Helpers

    private func weightDisplay(for kg: Double) -> String {
        if isMetric {
            return String(format: "%.1f kg", kg)
        }
        let lbs = kg / 0.453592
        return String(format: "%.1f lb", lbs)
    }

    private func goalDateText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.setLocalizedDateFormatFromTemplate("MMMd")
        return formatter.string(from: date)
    }

    private func selectDefaultProductIfNeeded() {
        if let selectedProduct,
           storeManager.products.contains(where: { $0.id == selectedProduct.id }) {
            return
        }
        selectedProduct = storeManager.yearlyProduct
            ?? storeManager.monthlyProduct
            ?? storeManager.weeklyProduct
    }
}
