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

    private let testimonials: [(title: String, author: String, quote: String)] = [
        ("Thankful", "Joel819", "This app is great, am recommending this to my friends."),
        ("One of the best", "2MitiN6", "Yours changes my life in real time for free."),
        ("Cool App", "Sloosi", "I wrote a suggestion on GitHub and was approved and done instantly.")
    ]

    var body: some View {
        VStack(spacing: 0) {
            ScrollView(showsIndicators: false) {
                VStack(spacing: 24) {
                    personalizedHeader
                    socialProofBlock
                    tierCards
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

            subscribeButton
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
            Image(systemName: "sparkles")
                .font(.system(size: 38))
                .foregroundStyle(
                    LinearGradient(colors: AppColors.calorieGradient,
                                   startPoint: .topLeading,
                                   endPoint: .bottomTrailing)
                )

            Text(headlineCopy)
                .font(.system(size: 26, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            Text("Your plan is ready — let's keep the momentum going.")
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
            return String(localized: "Unlock your full plan")
        }
        let weightDisplay: String
        if isMetric {
            weightDisplay = String(format: "%.1f kg", target)
        } else {
            let lbs = target / 0.453592
            weightDisplay = String(format: "%.1f lb", lbs)
        }
        return String(localized: "You're \(weeks) weeks from \(weightDisplay). Let's get you there.")
    }

    // MARK: - Social proof

    private var socialProofBlock: some View {
        VStack(spacing: 14) {
            HStack(spacing: 6) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 14, weight: .semibold))
                        .foregroundStyle(AppColors.calorie)
                }
                Text("4.8 · Loved by thousands")
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .foregroundStyle(.primary)
                    .padding(.leading, 4)
            }

            VStack(spacing: 10) {
                ForEach(testimonials.indices, id: \.self) { idx in
                    testimonialCard(testimonials[idx])
                }
            }
        }
    }

    private func testimonialCard(_ review: (title: String, author: String, quote: String)) -> some View {
        VStack(alignment: .leading, spacing: 7) {
            HStack(spacing: 2) {
                ForEach(0..<5, id: \.self) { _ in
                    Image(systemName: "star.fill")
                        .font(.system(size: 10, weight: .semibold))
                        .foregroundStyle(AppColors.calorie)
                }
                Spacer(minLength: 8)
                Text(review.author)
                    .font(.system(.caption2, design: .rounded, weight: .medium))
                    .foregroundStyle(.secondary)
            }

            Text(review.title)
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)

            Text(review.quote)
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(12)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(AppColors.appCard)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
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
                    tierCard(product: yearly, badge: String(localized: "Best Value"))
                }
                if let monthly = storeManager.monthlyProduct {
                    tierCard(product: monthly, badge: nil)
                }
                if let weekly = storeManager.weeklyProduct {
                    tierCard(product: weekly, badge: nil)
                }
            }
        }
    }

    private func tierCard(product: PlusProduct, badge: String?) -> some View {
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
                }
                Spacer()
                Text(product.displayPrice)
                    .font(.system(.body, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? AppColors.calorie : Color.secondary.opacity(0.3))
            }
            .padding(16)
            .background(AppColors.appCard, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? AppColors.calorie : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }

    // MARK: - Subscribe CTA

    private var subscribeButton: some View {
        Button {
            guard let product = selectedProduct else { return }
            Task {
                let success = await storeManager.purchase(product)
                if success {
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
        guard let product = selectedProduct else { return String(localized: "Subscribe") }
        return product.introOfferCopy != nil
            ? String(localized: "Start 3-Day Free Trial")
            : String(localized: "Subscribe")
    }

    // MARK: - Footer

    private var footerLinks: some View {
        HStack(spacing: 18) {
            Button {
                Task {
                    let success = await storeManager.restorePurchases()
                    if success { hasCompletedOnboarding = true }
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
