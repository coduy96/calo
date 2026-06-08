# Paywall Redesign Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Redesign the hard paywall (`PaywallView.swift`) to be logo-first and conversion-optimized — honest `SAVE X%` badge, trial-forward CTA, 2-pill trust row — and remove the truncating privacy pill from the onboarding paywall.

**Architecture:** A pure, testable `savingsPercent` helper on `StoreManager` computes honest savings from real `Decimal` prices; a new `savingsText` field on `PlusProduct` carries it to the UI. `PaywallView` is rebuilt as a `ScrollView` of hero/features/plans with the CTA + trust row + footer pinned via `.safeAreaInset(edge: .bottom)` so nothing truncates or is cut off on small devices. All accents go through `AppColors.*` so the screen respects the user's theme color and dark mode.

**Tech Stack:** SwiftUI, StoreKit 2 + RevenueCat, Swift Testing (`@Test`), XcodeBuildMCP for build/test/run.

**Reference spec:** `docs/superpowers/specs/2026-06-08-paywall-redesign-design.md`

---

## File Structure

- `ios/calorietracker/Stores/StoreManager.swift` — add `PlusProduct.savingsText`, the pure `StoreManager.savingsPercent(...)` helper, the `savingsText(forProductID:priceByID:)` wrapper, and wire both load paths.
- `ios/calorietrackerTests/StoreManagerSavingsTests.swift` — **new** unit tests for `savingsPercent`.
- `ios/calorietracker/Views/PaywallView.swift` — full visual redesign.
- `ios/calorietracker/Views/InlinePaywallStepView.swift` — remove one trust pill.

Task order: **Task 1** (helper + tests, pure logic) → **Task 2** (field + wiring, depends on helper) → **Task 3** (PaywallView, depends on `savingsText`) → **Task 4** (onboarding pill, independent).

---

## Task 1: Pure `savingsPercent` helper + unit tests

**Files:**
- Test (create): `ios/calorietrackerTests/StoreManagerSavingsTests.swift`
- Modify: `ios/calorietracker/Stores/StoreManager.swift` (add `nonisolated static func savingsPercent`)

- [ ] **Step 1: Write the failing test**

Create `ios/calorietrackerTests/StoreManagerSavingsTests.swift`:

```swift
import Testing
import Foundation
@testable import calorietracker

struct StoreManagerSavingsTests {

    @Test func yearlyVsMonthlyComputesRoundedPercent() {
        // 4.99 * 12 = 59.88 ; 1 - 29.99/59.88 = 0.4992 -> 50
        #expect(StoreManager.savingsPercent(yearly: 29.99, monthly: 4.99, weekly: 1.99) == 50)
    }

    @Test func fallsBackToWeeklyWhenNoMonthly() {
        // 1.99 * 52 = 103.48 ; 1 - 29.99/103.48 = 0.7102 -> 71
        #expect(StoreManager.savingsPercent(yearly: 29.99, monthly: nil, weekly: 1.99) == 71)
    }

    @Test func nilWhenNoBaselinePrices() {
        #expect(StoreManager.savingsPercent(yearly: 29.99, monthly: nil, weekly: nil) == nil)
    }

    @Test func nilWhenSavingsNotPositive() {
        // yearly (60) costs more than monthly annualized (59.88) -> negative -> nil
        #expect(StoreManager.savingsPercent(yearly: 60, monthly: 4.99, weekly: nil) == nil)
    }

    @Test func nilWhenYearlyNotPositive() {
        #expect(StoreManager.savingsPercent(yearly: 0, monthly: 4.99, weekly: nil) == nil)
    }
}
```

- [ ] **Step 2: Run the test to verify it fails (does not compile yet)**

Run via XcodeBuildMCP `test_sim` (scheme `calorietracker`) limited to the new suite, or CLI:

```bash
xcodebuild test -project ios/calorietracker.xcodeproj -scheme calorietracker \
  -destination 'platform=iOS Simulator,name=iPhone 16' \
  -only-testing:calorietrackerTests/StoreManagerSavingsTests
```

Expected: **FAIL** — compile error, `type 'StoreManager' has no member 'savingsPercent'`.

- [ ] **Step 3: Implement the minimal helper**

In `ios/calorietracker/Stores/StoreManager.swift`, add this method to the `StoreManager` class (place it right after the `productSortRank(_:)` static method, around line 358):

```swift
    /// Savings of the yearly plan vs the monthly plan annualized (×12),
    /// falling back to weekly (×52) when there is no monthly plan.
    /// Returns nil when not computable or when savings would be < 1%.
    nonisolated static func savingsPercent(yearly: Decimal, monthly: Decimal?, weekly: Decimal?) -> Int? {
        let yearlyValue = (yearly as NSDecimalNumber).doubleValue
        guard yearlyValue > 0 else { return nil }

        let baseline: Double?
        if let monthly {
            baseline = (monthly as NSDecimalNumber).doubleValue * 12
        } else if let weekly {
            baseline = (weekly as NSDecimalNumber).doubleValue * 52
        } else {
            baseline = nil
        }
        guard let baseline, baseline > 0 else { return nil }

        let percent = (1 - yearlyValue / baseline) * 100
        let rounded = Int(percent.rounded())
        return rounded >= 1 ? rounded : nil
    }
```

- [ ] **Step 4: Run the test to verify it passes**

Run the same command as Step 2. Expected: **PASS** (5 tests).

- [ ] **Step 5: Commit**

```bash
git add ios/calorietrackerTests/StoreManagerSavingsTests.swift ios/calorietracker/Stores/StoreManager.swift
git commit -m "$(printf 'feat(paywall): honest savingsPercent helper + tests\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
```

---

## Task 2: `PlusProduct.savingsText` + wire both load paths

**Files:**
- Modify: `ios/calorietracker/Stores/StoreManager.swift`
  - `PlusProduct` struct (~line 47): add field
  - `loadStoreKitProducts()` (~line 136): build price map, pass `savingsText`
  - `plusProducts(from:)` (~line 324): build price map, pass `savingsText`
  - add `savingsText(forProductID:priceByID:)` instance helper

- [ ] **Step 1: Add the `savingsText` field to `PlusProduct`**

In `PlusProduct`, insert the new field immediately after `pricePerDayText`:

```swift
    /// Localized per-day price (e.g. "$0.27"). Populated for yearly products only.
    let pricePerDayText: String?
    /// Honest savings vs the monthly plan annualized (e.g. "SAVE 50%").
    /// Populated for the yearly product only; nil when not computable.
    let savingsText: String?
    fileprivate let source: Source
```

- [ ] **Step 2: Add the `savingsText` instance helper**

In the `StoreManager` class, add next to the other `detail`/price helpers (e.g. right after the `savingsPercent` method from Task 1):

```swift
    private func savingsText(forProductID productID: String, priceByID: [String: Decimal]) -> String? {
        guard productID == Self.yearlyID, let yearly = priceByID[Self.yearlyID] else { return nil }
        guard let percent = Self.savingsPercent(
            yearly: yearly,
            monthly: priceByID[Self.monthlyID],
            weekly: priceByID[Self.weeklyID]
        ) else { return nil }
        return String(localized: "SAVE \(percent)%")
    }
```

- [ ] **Step 3: Wire `loadStoreKitProducts()`**

Replace the body from `let storeProducts = ...` through the `.sorted { ... }` (currently ~lines 138–151) with:

```swift
            let storeProducts = try await Product.products(for: Self.allProductIDs)
            let priceByID = Dictionary(
                storeProducts.map { ($0.id, $0.price) },
                uniquingKeysWith: { first, _ in first }
            )
            products = storeProducts.map { product in
                PlusProduct(
                    id: product.id,
                    productID: product.id,
                    title: Self.title(forProductID: product.id),
                    displayPrice: product.displayPrice,
                    detail: detail(for: product),
                    introOfferCopy: introCopy(for: product),
                    pricePerDayText: pricePerDayText(for: product),
                    savingsText: savingsText(forProductID: product.id, priceByID: priceByID),
                    source: .storeKit(product)
                )
            }
            .sorted { Self.productSortRank($0.productID) < Self.productSortRank($1.productID) }
```

- [ ] **Step 4: Wire `plusProducts(from:)`**

In `plusProducts(from:)`, replace the final `return packages.map { ... }.sorted { ... }` block (currently ~lines 336–348) with:

```swift
        let priceByID = Dictionary(
            packages.map { ($0.storeProduct.productIdentifier, $0.storeProduct.price) },
            uniquingKeysWith: { first, _ in first }
        )
        return packages.map { package in
            PlusProduct(
                id: package.storeProduct.productIdentifier,
                productID: package.storeProduct.productIdentifier,
                title: title(for: package),
                displayPrice: package.localizedPriceString,
                detail: detail(for: package),
                introOfferCopy: introCopy(for: package),
                pricePerDayText: pricePerDayText(for: package),
                savingsText: savingsText(forProductID: package.storeProduct.productIdentifier, priceByID: priceByID),
                source: .revenueCat(package)
            )
        }
        .sorted { Self.productSortRank($0.productID) < Self.productSortRank($1.productID) }
```

- [ ] **Step 5: Build to verify it compiles + tests still pass**

Build via XcodeBuildMCP `build_sim` (scheme `calorietracker`), or CLI:

```bash
xcodebuild build -project ios/calorietracker.xcodeproj -scheme calorietracker \
  -destination 'platform=iOS Simulator,name=iPhone 16'
```

Expected: **BUILD SUCCEEDED**. Then re-run the Task 1 test command — still **PASS** (no regressions).

- [ ] **Step 6: Commit**

```bash
git add ios/calorietracker/Stores/StoreManager.swift
git commit -m "$(printf 'feat(paywall): expose savingsText on PlusProduct (StoreKit + RevenueCat)\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
```

---

## Task 3: Redesign `PaywallView.swift`

**Files:**
- Modify (full rewrite): `ios/calorietracker/Views/PaywallView.swift`

- [ ] **Step 1: Replace the entire file**

Replace the full contents of `ios/calorietracker/Views/PaywallView.swift` with:

```swift
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
```

- [ ] **Step 2: Build to verify it compiles**

Build via XcodeBuildMCP `build_sim` (scheme `calorietracker`) or the CLI command from Task 2 Step 5. Expected: **BUILD SUCCEEDED**.

- [ ] **Step 3: Manual verification in the simulator (the paywall is the launch gate)**

Run the app via XcodeBuildMCP `build_run_sim`. Because the paywall only shows when not subscribed, launch with the bypass disabled (default). Capture a screenshot with XcodeBuildMCP `screenshot` and confirm:
- The **Voidpen logo** shows in the gradient halo (no sparkle).
- Yearly card shows a `SAVE …%` badge (or "Best Value" if prices unavailable) and is pre-selected.
- CTA reads "Start 3-Day Free Trial" (when a trial offer is configured) and is enabled.
- Trust row shows "Cancel anytime" (+ "3 days free" when a trial exists) with **no "…" truncation**.
- Restore / Terms / Privacy are visible at the bottom.

Repeat on a small device (e.g. iPhone SE (3rd generation)) and a large device, in **light and dark** appearance, and confirm the CTA stays pinned/visible and nothing is cut off. (Set appearance via XcodeBuildMCP simulator appearance, or the simulator's Settings.)

- [ ] **Step 4: Commit**

```bash
git add ios/calorietracker/Views/PaywallView.swift
git commit -m "$(printf 'feat(paywall): logo-first redesign with savings badge, trust pills, pinned CTA\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
```

---

## Task 4: Remove the truncating privacy pill from the onboarding paywall

**Files:**
- Modify: `ios/calorietracker/Views/InlinePaywallStepView.swift` (`trustStrip`, ~lines 338–343)

- [ ] **Step 1: Delete the privacy pill line**

In `InlinePaywallStepView.swift`, change `trustStrip` from:

```swift
    private var trustStrip: some View {
        HStack(spacing: 8) {
            trustPill(icon: "lock.shield.fill", label: String(localized: "Private. On-device."))
            trustPill(icon: "arrow.uturn.backward.circle.fill", label: String(localized: "Cancel anytime"))
            trustPill(icon: "gift.fill", label: String(localized: "3 days free"))
        }
    }
```

to:

```swift
    private var trustStrip: some View {
        HStack(spacing: 8) {
            trustPill(icon: "arrow.uturn.backward.circle.fill", label: String(localized: "Cancel anytime"))
            trustPill(icon: "gift.fill", label: String(localized: "3 days free"))
        }
    }
```

- [ ] **Step 2: Build to verify it compiles**

Build via XcodeBuildMCP `build_sim` (scheme `calorietracker`). Expected: **BUILD SUCCEEDED**.

- [ ] **Step 3: Manual verification**

Run the app and step through onboarding to the inline paywall (or use the screenshot-seeding/onboarding entry). Confirm the trust strip now shows exactly two pills — "Cancel anytime" and "3 days free" — each in full with **no "…" ellipsis**, including on iPhone SE.

- [ ] **Step 4: Commit**

```bash
git add ios/calorietracker/Views/InlinePaywallStepView.swift
git commit -m "$(printf 'fix(paywall): drop truncating "Private. On-device." trust pill\n\nCo-Authored-By: Claude Opus 4.8 (1M context) <noreply@anthropic.com>')"
```

---

## Final verification

- [ ] Full test suite passes: run XcodeBuildMCP `test_sim` (scheme `calorietracker`) with no `-only-testing` filter. Expected: all tests **PASS**.
- [ ] `git log --oneline -4` shows the four task commits on the `paywall-redesign` branch.
- [ ] Re-read the spec's "What Stays Unchanged" list and confirm: no price/product IDs changed, purchase/restore/entitlement logic untouched, Terms/Privacy/Restore intact.
```
