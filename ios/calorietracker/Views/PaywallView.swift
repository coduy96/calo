import SwiftUI

/// Hard paywall: the only route into the app is an active subscription.
/// Leads with the Voidpen logo and surfaces honest value framing — a live
/// `SAVE X%` badge on the yearly plan (computed from real prices) and the
/// 3-day free trial via `PlusProduct.introOfferCopy`. No dark patterns.
/// Restore / Terms / Privacy live at the bottom (required by App Store review).
struct PaywallView: View {
    @Environment(StoreManager.self) private var storeManager
    @State private var selectedProduct: PlusProduct?

    // Replace these with your actual marketing site links before submitting.
    private let termsURL = URL(string: "https://voidpen.com/terms")!
    private let privacyURL = URL(string: "https://voidpen.com/privacy")!

    var body: some View {
        ScrollView {
            VStack(spacing: 0) {
                header
                featureList
                    .padding(.top, 24)
                planCards
                    .padding(.top, 28)
            }
            .padding(.top, 32)
            .padding(.bottom, 12)
            .frame(maxWidth: .infinity)
        }
        .background(AppColors.appBackground.ignoresSafeArea())
        .safeAreaInset(edge: .bottom) { bottomBar }
        .task {
            await storeManager.loadProducts()
            selectDefaultProductIfNeeded()
        }
        .onChange(of: storeManager.products.map(\.id)) { _, _ in
            selectDefaultProductIfNeeded()
        }
    }

    // MARK: - Header

    private var header: some View {
        VStack(spacing: 8) {
            logoHalo
            Text("VOIDPEN PLUS")
                .font(.system(.caption, design: .rounded, weight: .heavy))
                .tracking(2)
                .foregroundStyle(AppColors.calorie)
                .padding(.top, 4)
            Text("Everything unlocked")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 24)
    }

    private var logoHalo: some View {
        ZStack {
            Circle()
                .fill(
                    RadialGradient(
                        colors: [AppColors.calorie.opacity(0.28), AppColors.calorie.opacity(0.0)],
                        center: .center, startRadius: 4, endRadius: 58
                    )
                )
                .frame(width: 116, height: 116)
            Circle()
                .fill(AppColors.appCard)
                .frame(width: 78, height: 78)
                .shadow(color: AppColors.calorie.opacity(0.22), radius: 10, y: 4)
            Image("onboardingLogo")
                .resizable()
                .scaledToFit()
                .frame(width: 48, height: 48)
        }
    }

    // MARK: - Features

    private var featureList: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureRow("Snap or speak any meal — instant macros")
            featureRow("Personal AI Coach trained on your data")
            featureRow("Smart nutrition-label scanning")
            featureRow("Weight forecasts and trend analysis")
        }
        .padding(.horizontal, 32)
    }

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 11) {
            Image(systemName: "checkmark")
                .font(.system(size: 11, weight: .bold))
                .foregroundStyle(.white)
                .frame(width: 22, height: 22)
                .background(
                    LinearGradient(colors: AppColors.calorieGradient, startPoint: .topLeading, endPoint: .bottomTrailing),
                    in: RoundedRectangle(cornerRadius: 7, style: .continuous)
                )
            Text(text)
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
    }

    // MARK: - Plan cards

    private var planCards: some View {
        VStack(spacing: 10) {
            if let yearly = storeManager.yearlyProduct {
                paywallCard(product: yearly, badge: yearly.savingsText ?? "Best Value")
            }
            if let monthly = storeManager.monthlyProduct {
                paywallCard(product: monthly, badge: nil)
            }
            if let weekly = storeManager.weeklyProduct {
                paywallCard(product: weekly, badge: nil)
            }
        }
        .padding(.horizontal, 24)
    }

    private func paywallCard(product: PlusProduct, badge: String?) -> some View {
        let isSelected = selectedProduct?.id == product.id
        return Button {
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
                                    LinearGradient(colors: AppColors.calorieGradient, startPoint: .leading, endPoint: .trailing),
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

    // MARK: - Bottom bar (pinned, always visible)

    private var bottomBar: some View {
        VStack(spacing: 0) {
            if let error = storeManager.purchaseError {
                Text(error)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
                    .padding(.bottom, 8)
            }
            subscribeButton
            trustRow
                .padding(.top, 12)
            footerLinks
                .padding(.top, 12)
        }
        .padding(.top, 12)
        .padding(.bottom, 8)
        .background(AppColors.appBackground)
    }

    private var subscribeButton: some View {
        Button {
            guard let product = selectedProduct else { return }
            Task { await storeManager.purchase(product) }
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
                LinearGradient(colors: AppColors.calorieGradient, startPoint: .leading, endPoint: .trailing),
                in: RoundedRectangle(cornerRadius: 16, style: .continuous)
            )
            .shadow(color: AppColors.calorie.opacity(0.3), radius: 8, y: 4)
        }
        .padding(.horizontal, 24)
        .disabled(selectedProduct == nil || storeManager.isPurchasing)
    }

    private var trustRow: some View {
        HStack(spacing: 8) {
            trustPill(icon: "arrow.uturn.backward", label: "Cancel anytime")
            if selectedProduct?.introOfferCopy != nil {
                trustPill(icon: "gift", label: "3 days free")
            }
        }
        .padding(.horizontal, 24)
    }

    private func trustPill(icon: String, label: String) -> some View {
        HStack(spacing: 5) {
            Image(systemName: icon)
                .font(.system(size: 11, weight: .semibold))
            Text(label)
                .font(.system(.caption2, design: .rounded, weight: .medium))
                .fixedSize(horizontal: true, vertical: false)
        }
        .foregroundStyle(.secondary)
        .padding(.horizontal, 12)
        .padding(.vertical, 7)
        .background(Capsule().fill(AppColors.appCard))
        .overlay(Capsule().strokeBorder(Color.primary.opacity(0.06), lineWidth: 1))
    }

    private var footerLinks: some View {
        HStack(spacing: 18) {
            Button("Restore Purchases") {
                Task { await storeManager.restorePurchases() }
            }
            Link("Terms", destination: termsURL)
            Link("Privacy", destination: privacyURL)
        }
        .font(.system(.footnote, design: .rounded, weight: .medium))
        .foregroundStyle(.secondary)
    }

    // MARK: - Helpers

    private var subscribeButtonTitle: String {
        guard let product = selectedProduct else { return "Subscribe" }
        return product.introOfferCopy != nil ? "Start 3-Day Free Trial" : "Subscribe"
    }

    private func selectDefaultProductIfNeeded() {
        if let selectedProduct,
           storeManager.products.contains(where: { $0.id == selectedProduct.id }) {
            return
        }
        selectedProduct = storeManager.yearlyProduct ?? storeManager.monthlyProduct ?? storeManager.weeklyProduct
    }
}
