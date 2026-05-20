import SwiftUI

/// Hard paywall: the only route into the app is an active subscription.
/// Surfaces the 3-day free trial via `PlusProduct.introOfferCopy` (set up
/// in App Store Connect as a subscription introductory offer). Restore
/// Purchases lives at the bottom so existing subscribers can move to a new
/// device without an account. Terms / Privacy links are required by App
/// Store review and live next to Restore.
struct PaywallView: View {
    @Environment(StoreManager.self) private var storeManager
    @State private var selectedProduct: PlusProduct?

    // Replace these with your actual marketing site links before submitting.
    private let termsURL = URL(string: "https://voidpen.com/terms")!
    private let privacyURL = URL(string: "https://voidpen.com/privacy")!

    var body: some View {
        VStack(spacing: 0) {
            Spacer(minLength: 24)

            VStack(spacing: 12) {
                Image(systemName: "sparkles")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(colors: AppColors.calorieGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )

                Text("Unlock Voidpen")
                    .font(.system(size: 28, weight: .bold, design: .rounded))
                    .multilineTextAlignment(.center)

                Text("AI food scans, voice logging, and your personal Coach — all in one private tracker.")
                    .font(.system(.callout, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.horizontal, 24)
            }

            VStack(alignment: .leading, spacing: 10) {
                featureRow("Unlimited photo + voice food logging")
                featureRow("Personal AI Coach trained on your data")
                featureRow("Smart nutrition label scanning")
                featureRow("Weight forecasts and trend analysis")
            }
            .font(.system(.subheadline, design: .rounded))
            .foregroundStyle(.primary)
            .padding(.horizontal, 32)
            .padding(.top, 20)

            Spacer(minLength: 24)

            // Plan cards
            VStack(spacing: 12) {
                if let yearly = storeManager.yearlyProduct {
                    paywallCard(product: yearly, badge: "Best Value")
                }
                if let monthly = storeManager.monthlyProduct {
                    paywallCard(product: monthly, badge: nil)
                }
                if let weekly = storeManager.weeklyProduct {
                    paywallCard(product: weekly, badge: nil)
                }
            }
            .padding(.horizontal, 24)

            Spacer(minLength: 16)

            // Subscribe button
            Button {
                guard let product = selectedProduct else { return }
                Task {
                    await storeManager.purchase(product)
                }
            } label: {
                Group {
                    if storeManager.isPurchasing {
                        ProgressView()
                            .tint(.white)
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

            if let error = storeManager.purchaseError {
                Text(error)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.red)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
                    .padding(.horizontal, 24)
            }

            HStack(spacing: 18) {
                Button("Restore Purchases") {
                    Task { await storeManager.restorePurchases() }
                }
                Link("Terms", destination: termsURL)
                Link("Privacy", destination: privacyURL)
            }
            .font(.system(.footnote, design: .rounded, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.top, 14)
            .padding(.bottom, 28)
        }
        .background(AppColors.appBackground.ignoresSafeArea())
        .task {
            await storeManager.loadProducts()
            selectDefaultProductIfNeeded()
        }
        .onChange(of: storeManager.products.map(\.id)) { _, _ in
            selectDefaultProductIfNeeded()
        }
    }

    private var subscribeButtonTitle: String {
        guard let product = selectedProduct else { return "Subscribe" }
        return product.introOfferCopy != nil ? "Start Free Trial" : "Subscribe"
    }

    private func selectDefaultProductIfNeeded() {
        if let selectedProduct,
           storeManager.products.contains(where: { $0.id == selectedProduct.id }) {
            return
        }
        selectedProduct = storeManager.yearlyProduct ?? storeManager.monthlyProduct ?? storeManager.weeklyProduct
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

    private func featureRow(_ text: String) -> some View {
        HStack(spacing: 10) {
            Image(systemName: "checkmark.circle.fill")
                .foregroundStyle(AppColors.calorie)
            Text(text)
            Spacer(minLength: 0)
        }
    }
}
