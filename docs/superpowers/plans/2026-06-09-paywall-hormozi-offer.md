# Paywall Honest-Hormozi Offer — Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Add three honest value/risk-reversal levers (a "what this replaces" value card, a risk-reversal line, and a per-day price anchor) to both Voidpen paywalls, reframing copy toward outcomes — no pricing/tier changes, no dark patterns.

**Architecture:** One new shared SwiftUI file (`PaywallOfferComponents.swift`) holds the reusable offer pieces and the only hard-coded marketing constants. `PaywallView` (hard gate) and `InlinePaywallStepView` (onboarding) consume them. All prices/savings/trial/per-day data already exist on `PlusProduct`; StoreManager is untouched.

**Tech Stack:** SwiftUI, iOS 17.6+ (Liquid Glass on 26+), existing `AppColors` design system, StoreKit/RevenueCat via `StoreManager`. Xcode synchronized folder — new `.swift` files under `ios/calorietracker/` are auto-included (no pbxproj edit).

**Verification model:** This is view/layout work; the repo has no view-test target. Each task's gate is **a clean simulator build (zero errors/warnings)**; the final task adds **simulator screenshots** of both paywalls. This matches the project's established practice.

**Spec:** `docs/superpowers/specs/2026-06-09-paywall-hormozi-offer-design.md`

---

### Task 1: Shared offer components

**Files:**
- Create: `ios/calorietracker/Views/PaywallOfferComponents.swift`

- [ ] **Step 1: Create the file with all three components**

```swift
import SwiftUI

/// Honest "Grand Slam" offer components shared by both paywalls.
/// Persuasion comes from real-world price anchoring + risk reversal (the free
/// trial) — no dark patterns. See
/// docs/superpowers/specs/2026-06-09-paywall-hormozi-offer-design.md.

/// One real-world alternative the user would otherwise pay for.
/// `defaults` holds the ONLY hard-coded marketing numbers in the paywall —
/// deliberately conservative market floors. Edit here to tune the comparison.
struct ReplacedCost: Identifiable {
    let id = UUID()
    let label: String
    let price: String

    static let defaults: [ReplacedCost] = [
        ReplacedCost(label: String(localized: "1:1 nutritionist"),
                     price: String(localized: "$90 / visit")),
        ReplacedCost(label: String(localized: "Macro-coaching app"),
                     price: String(localized: "$30 / mo")),
        ReplacedCost(label: String(localized: "Premium calorie tracker"),
                     price: String(localized: "$10 / mo")),
    ]
}

/// "What this replaces" value-anchor card (hard-paywall hero).
/// Pass the yearly monthly-equivalent ("$X/mo") as `voidpenPrice` with
/// `showsFromPrefix: true` so it renders "from $X / mo".
struct ReplacesValueCard: View {
    let voidpenPrice: String
    var showsFromPrefix: Bool = true
    var rows: [ReplacedCost] = ReplacedCost.defaults

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("What this replaces")
                .font(.system(.subheadline, design: .rounded, weight: .bold))
                .foregroundStyle(.primary)

            VStack(spacing: 9) {
                ForEach(rows) { row in
                    HStack {
                        Text(row.label)
                            .font(.system(.subheadline, design: .rounded))
                            .foregroundStyle(.secondary)
                        Spacer(minLength: 8)
                        Text(row.price)
                            .font(.system(.subheadline, design: .rounded, weight: .medium))
                            .foregroundStyle(.secondary)
                            .fixedSize(horizontal: true, vertical: false)
                    }
                }
            }

            Divider().overlay(Color.primary.opacity(0.08))

            HStack(alignment: .firstTextBaseline) {
                Text("Voidpen Plus")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .foregroundStyle(.primary)
                Spacer(minLength: 8)
                Text(voidpenPriceText)
                    .font(.system(.subheadline, design: .rounded, weight: .heavy))
                    .foregroundStyle(AppColors.calorie)
                    .fixedSize(horizontal: true, vertical: false)
            }

            Text("Everything, one price.")
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(AppColors.appCard, in: RoundedRectangle(cornerRadius: 16, style: .continuous))
        .overlay(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .strokeBorder(Color.primary.opacity(0.06), lineWidth: 1)
        )
    }

    private var voidpenPriceText: String {
        showsFromPrefix
            ? String(localized: "from \(voidpenPrice)")
            : voidpenPrice
    }
}

/// Risk-reversal line shown directly above the subscribe CTA. The free trial
/// IS the guarantee; no money-back claim (Apple owns refunds).
struct RiskReversalLine: View {
    let trialEligible: Bool

    var body: some View {
        Text(copy)
            .font(.system(.footnote, design: .rounded, weight: .semibold))
            .multilineTextAlignment(.center)
            .foregroundStyle(.primary)
            .fixedSize(horizontal: false, vertical: true)
            .frame(maxWidth: .infinity)
    }

    private var copy: String {
        trialEligible
            ? String(localized: "3 days free. Cancel in 2 taps. $0 if it's not for you.")
            : String(localized: "Cancel anytime in 2 taps.")
    }
}
```

- [ ] **Step 2: Build to verify it compiles**

Run (XcodeBuildMCP): `session_show_defaults` then `build_sim` (empty args).
Expected: BUILD SUCCEEDED, zero errors, zero warnings. The new file is
auto-included by the synchronized folder.

- [ ] **Step 3: Commit**

```bash
git add ios/calorietracker/Views/PaywallOfferComponents.swift
git commit -m "feat(paywall): shared honest-offer components (value card, risk-reversal, anchors)"
```

---

### Task 2: Wire offer into the hard paywall

**Files:**
- Modify: `ios/calorietracker/Views/PaywallView.swift`

- [ ] **Step 1: Outcome headline**

Replace the header subtitle (currently `Text("Everything unlocked")`):

```swift
            Text("Hit your goal. No guesswork.")
                .font(.system(size: 28, weight: .bold, design: .rounded))
                .multilineTextAlignment(.center)
```

- [ ] **Step 2: Reframe the four feature rows**

Replace the body of `featureList` with:

```swift
    private var featureList: some View {
        VStack(alignment: .leading, spacing: 12) {
            featureRow("Snap or say any meal — macros in seconds")
            featureRow("A personal AI coach that learns your body")
            featureRow("Scan any label, get the real numbers")
            featureRow("See where your weight is actually heading")
        }
        .padding(.horizontal, 32)
    }
```

- [ ] **Step 3: Insert the value card into the scroll stack**

In `body`, between `featureList` and `planCards`, add the value card:

```swift
                featureList
                    .padding(.top, 24)
                valueCard
                    .padding(.top, 24)
                planCards
                    .padding(.top, 24)
```

(Note: `planCards` top padding changes from 28 to 24 for even rhythm.)

- [ ] **Step 4: Add the `valueCard` computed view**

Add alongside the other MARK sections (e.g. after `planCards`):

```swift
    // MARK: - Value anchor

    @ViewBuilder
    private var valueCard: some View {
        if let voidpenPrice = storeManager.yearlyProduct?.detail {
            ReplacesValueCard(voidpenPrice: voidpenPrice, showsFromPrefix: true)
                .padding(.horizontal, 24)
        } else if let monthly = storeManager.monthlyProduct?.displayPrice {
            ReplacesValueCard(voidpenPrice: monthly, showsFromPrefix: false)
                .padding(.horizontal, 24)
        }
    }
```

- [ ] **Step 5: Add the per-day anchor to the plan card**

In `paywallCard`, inside the leading `VStack(alignment: .leading, spacing: 4)`,
immediately after the `if let intro … else … } ` block that shows
intro/detail, add:

```swift
                    if let perDay = product.pricePerDayText {
                        Text("Less than \(perDay)/day")
                            .font(.system(.caption2, design: .rounded, weight: .semibold))
                            .foregroundStyle(AppColors.calorie.opacity(0.9))
                    }
```

(`pricePerDayText` is populated for the yearly product only, so it shows there.)

- [ ] **Step 6: Add the risk-reversal line above the subscribe button**

In `bottomBar`, between the `purchaseError` block and `subscribeButton`, add:

```swift
            RiskReversalLine(trialEligible: selectedProduct?.introOfferCopy != nil)
                .padding(.horizontal, 24)
                .padding(.bottom, 10)
            subscribeButton
```

- [ ] **Step 7: Strengthen the CTA copy**

Replace `subscribeButtonTitle`:

```swift
    private var subscribeButtonTitle: String {
        guard let product = selectedProduct else { return "Unlock Everything" }
        return product.introOfferCopy != nil ? "Start My 3-Day Free Trial" : "Unlock Everything"
    }
```

- [ ] **Step 8: Build to verify it compiles**

Run (XcodeBuildMCP): `build_sim`.
Expected: BUILD SUCCEEDED, zero errors, zero warnings.

- [ ] **Step 9: Commit**

```bash
git add ios/calorietracker/Views/PaywallView.swift
git commit -m "feat(paywall): value card, risk-reversal, per-day anchor + outcome copy on hard gate"
```

---

### Task 3: Wire offer into the onboarding paywall

**Files:**
- Modify: `ios/calorietracker/Views/InlinePaywallStepView.swift`

- [ ] **Step 1: Insert the compact value anchor after the loss section**

In `body`'s main `VStack(spacing: 22)`, between `lossSection` and `tierCards`,
add `compactValueAnchor`:

```swift
                    lossSection
                    compactValueAnchor
                    tierCards
```

- [ ] **Step 2: Add the `compactValueAnchor` computed view**

Add after the `lossSection` MARK block:

```swift
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
```

- [ ] **Step 3: Add the risk-reversal line above the CTA**

In the bottom `VStack(spacing: 10)` that holds `subscribeButton` and
`trialFinePrint`, add the line first:

```swift
            VStack(spacing: 10) {
                RiskReversalLine(trialEligible: selectedProduct?.introOfferCopy != nil)
                subscribeButton
                trialFinePrint
            }
```

- [ ] **Step 4: Build to verify it compiles**

Run (XcodeBuildMCP): `build_sim`.
Expected: BUILD SUCCEEDED, zero errors, zero warnings.

- [ ] **Step 5: Commit**

```bash
git add ios/calorietracker/Views/InlinePaywallStepView.swift
git commit -m "feat(paywall): compact value anchor + risk-reversal on onboarding paywall"
```

---

### Task 4: Visual verification of both paywalls

**Files:** none (verification only)

- [ ] **Step 1: Build & run on the simulator**

Run (XcodeBuildMCP): `build_run_sim`.
Expected: app launches in the booted simulator.

- [ ] **Step 2: Screenshot the hard paywall**

Drive to the hard paywall (sign-in/launch state for an unsubscribed user), then
`screenshot`. Confirm: outcome headline, reframed features, "What this replaces"
card showing real `from $X/mo`, yearly card showing `SAVE X%` + `Less than
$Y/day`, risk-reversal line, CTA "Start My 3-Day Free Trial", and
Restore/Terms/Privacy all present and untruncated.

- [ ] **Step 3: Screenshot the onboarding paywall**

Run through onboarding to `InlinePaywallStepView`, then `screenshot`. Confirm:
personalized headline, plan recap, loss section, compact value-anchor line,
tier cards with per-day anchor, risk-reversal line, CTA + fine print, footer.

- [ ] **Step 4: Reason through the no-trial fallback**

With `introOfferCopy == nil` (trial already used): risk-reversal line reads
"Cancel anytime in 2 taps." and the hard-paywall CTA reads "Unlock Everything".
Confirm by inspection of `RiskReversalLine.copy` and `subscribeButtonTitle`.

- [ ] **Step 5: Final confirmation**

No further commit needed (verification only). Report screenshots + build status.

---

## Self-Review

- **Spec coverage:** Lever 1 (value card) → Task 1 + Task 2.4 + Task 3.1–2; Lever 2 (risk-reversal) → Task 1 + Task 2.6 + Task 3.3; Lever 3 (per-day anchor) → Task 2.5; hard-paywall headline/features/CTA → Task 2.1/2.2/2.7; onboarding keeps loss section (unchanged) + adds anchor/line → Task 3; new shared file → Task 1; no pricing/StoreManager changes → none touched. All covered.
- **Placeholders:** none — every code step shows complete code; `$X`/`$Y` are runtime price strings, not plan placeholders.
- **Type consistency:** `ReplacesValueCard(voidpenPrice:showsFromPrefix:)` and `RiskReversalLine(trialEligible:)` are defined in Task 1 and called with the same signatures in Tasks 2–3. `product.pricePerDayText`, `yearlyProduct.detail`, `monthlyProduct.displayPrice`, `selectedProduct?.introOfferCopy` all exist on the current `PlusProduct`/`StoreManager`.
