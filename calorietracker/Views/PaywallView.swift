import SwiftUI
import StoreKit

struct PaywallView: View {
    @Environment(StoreManager.self) private var storeManager
    @State private var selectedProduct: Product?

    var body: some View {
        VStack(spacing: 0) {
            Spacer()

            // Header
            VStack(spacing: 8) {
                Image(systemName: "star.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(colors: [Color(hex: 0xFF375F), Color(hex: 0x8B2942)], startPoint: .topLeading, endPoint: .bottomTrailing)
                    )

                Text("Unlock Premium")
                    .font(.system(size: 28, weight: .bold, design: .rounded))

                Text("Unlimited scans, detailed insights,\nand personalized plans")
                    .font(.system(.callout, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }

            Spacer()

            // Plan cards
            VStack(spacing: 12) {
                if let yearly = storeManager.yearlyDiscountProduct ?? storeManager.yearlyProduct {
                    paywallCard(
                        product: yearly,
                        title: "Yearly",
                        badge: "Best Value",
                        detail: yearlyDetailText(yearly)
                    )
                }

                if let monthly = storeManager.monthlyProduct {
                    paywallCard(
                        product: monthly,
                        title: "Monthly",
                        badge: nil,
                        detail: "per month"
                    )
                }
            }
            .padding(.horizontal, 24)

            Spacer()

            // Subscribe button
            Button {
                guard let product = selectedProduct else { return }
                Task { await storeManager.purchase(product) }
            } label: {
                Group {
                    if storeManager.isPurchasing {
                        ProgressView()
                            .tint(Color(.systemBackground))
                    } else {
                        Text("Subscribe")
                            .font(.system(.body, design: .rounded, weight: .semibold))
                    }
                }
                .foregroundStyle(Color(.systemBackground))
                .frame(maxWidth: .infinity)
                .frame(height: 54)
                .background(Color.primary, in: Capsule())
            }
            .padding(.horizontal, 24)
            .disabled(selectedProduct == nil || storeManager.isPurchasing)

            // Error
            if let error = storeManager.purchaseError {
                Text(error)
                    .font(.system(.caption, design: .rounded))
                    .foregroundStyle(.red)
                    .padding(.top, 8)
                    .padding(.horizontal, 24)
            }

            // Restore + legal
            VStack(spacing: 8) {
                Button("Restore Purchases") {
                    Task { await storeManager.restorePurchases() }
                }
                .font(.system(.footnote, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)

                Text("No Commitment \u{2022} Cancel Anytime")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.tertiary)
            }
            .padding(.top, 12)
            .padding(.bottom, 36)
        }
        .background(AppColors.appBackground)
        .onAppear {
            // Default to yearly discount if available
            selectedProduct = storeManager.yearlyDiscountProduct ?? storeManager.yearlyProduct ?? storeManager.monthlyProduct
        }
    }

    private func yearlyDetailText(_ product: Product) -> String {
        let monthlyEquivalent = product.price / 12
        let formatter = NumberFormatter()
        formatter.numberStyle = .currency
        formatter.locale = product.priceFormatStyle.locale
        let monthlyStr = formatter.string(from: monthlyEquivalent as NSDecimalNumber) ?? ""
        return "\(monthlyStr)/mo"
    }

    private func paywallCard(product: Product, title: String, badge: String?, detail: String) -> some View {
        let isSelected = selectedProduct?.id == product.id

        return Button {
            withAnimation(.spring(response: 0.3)) { selectedProduct = product }
        } label: {
            HStack {
                VStack(alignment: .leading, spacing: 2) {
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
                    Text(title)
                        .font(.system(.body, design: .rounded, weight: .semibold))
                        .foregroundStyle(.primary)
                }
                Spacer()
                VStack(alignment: .trailing, spacing: 2) {
                    Text(product.displayPrice)
                        .font(.system(.body, design: .rounded, weight: .bold))
                        .foregroundStyle(.primary)
                    Text(detail)
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Image(systemName: isSelected ? "checkmark.circle.fill" : "circle")
                    .font(.system(size: 22))
                    .foregroundStyle(isSelected ? Color.primary : Color.secondary.opacity(0.3))
                    .padding(.leading, 8)
            }
            .padding(16)
            .background(AppColors.appCard, in: RoundedRectangle(cornerRadius: 16))
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .strokeBorder(isSelected ? Color.primary : Color.clear, lineWidth: 2)
            )
        }
        .buttonStyle(.plain)
    }
}
