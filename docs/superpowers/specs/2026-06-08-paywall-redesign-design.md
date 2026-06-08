# Paywall Redesign — Direction B "Premium Hero"

**Date:** 2026-06-08
**Status:** Approved design, pending spec review → implementation plan
**Author:** Dan + Claude (brainstorming session)

## Goal

Redesign the hard paywall (`PaywallView.swift`) to lift conversion while staying
honest and on-brand. The current screen leads with a generic `sparkles` SF Symbol
and adds no real conversion levers. The redesign leads with the **Voidpen logo**,
adds **honest value framing** (savings %, free trial), and surfaces **trust signals**
at the decision point — with **no dark patterns** (no fake countdowns, no fake
scarcity, no truncated/ellipsized text).

Driving constraints from the user: *"simple but effective, must show the Voidpen
logo, don't make my customer feel nonsense."*

## Scope

**In scope**
- Full visual redesign of `ios/calorietracker/Views/PaywallView.swift` (the hard
  paywall shown at app launch).
- One small data addition: a computed savings figure on the yearly product.
- Remove the buggy, truncating "Private. On-device." trust pill from
  `InlinePaywallStepView.swift` (the onboarding paywall) — this is the actual source
  of the "…" the user flagged.

**Out of scope (non-goals)**
- No change to prices, product IDs, or which products are offered
  (`voidpen.plus.weekly` / `.monthly` / `.yearly`). See [[feedback-no-live-changes-without-approval]].
- No change to purchase / restore / entitlement logic.
- No change to the hard-paywall gating in `ContentView.swift`.
- No redesign of `InlinePaywallStepView.swift` beyond removing the one privacy pill.
- No social proof / ratings (we have no honest data to show — would be "nonsense").
- No A/B testing infrastructure.

## Visual Design

Warm-cream background (`AppColors.appBackground`), SF Rounded throughout, all accent
colors via `AppColors.calorie` / `AppColors.calorieGradient` so the screen respects
the user's chosen app theme color (8 options; orange is default). Top → bottom:

1. **Logo halo** — the real `Image("onboardingLogo")` (~46pt) centered inside a
   circular container, sitting in a soft radial gradient "halo" tinted with
   `AppColors.calorie`. Replaces the `sparkles` symbol. Must read clearly in both
   light and dark mode (inner circle uses an adaptive fill, e.g. `AppColors.appCard`
   with a subtle shadow — not hardcoded white).
2. **Eyebrow label** — `VOIDPEN PLUS`, small, uppercase, tracked, in `AppColors.calorie`.
3. **Headline** — "Everything unlocked" (28pt-ish, bold, rounded).
4. **Benefit rows** — 4 rows, each a gradient rounded "check dot" + short benefit:
   - "Snap or speak any meal — instant macros"
   - "Personal AI Coach trained on your data"
   - "Smart nutrition-label scanning"
   - "Weight forecasts & trend analysis"
5. **Plan cards** — 3 cards (Yearly, Monthly, Weekly), yearly pre-selected:
   - Selected card: 2pt `AppColors.calorie` border (existing pattern).
   - **Yearly badge** = `product.savingsText` (e.g. "SAVE 50%") when computable,
     else falls back to "Best Value".
   - Secondary line: `introOfferCopy` when an intro offer is live
     (e.g. "3 days free, then $29.99/yr"), else `detail` (monthly-equivalent).
   - Right side: `displayPrice` + selection indicator (existing pattern).
6. **CTA** — full-width gradient button, 54pt, 16pt corners, existing shadow.
   Title: "Start 3-Day Free Trial" when the selected product has an intro offer,
   else "Subscribe" (existing `subscribeButtonTitle` logic, kept).
7. **Trust row** — exactly **2 pills**: "↩ Cancel anytime" and "🎁 3 days free".
   - The "3 days free" pill renders **only when an intro/free-trial offer is live**
     for the selected product; otherwise only "Cancel anytime" shows.
   - Pills use short labels and **wrap** (no `lineLimit(1)` + `minimumScaleFactor`
     truncation). They must **never** show an ellipsis.
8. **Footer** — "Restore Purchases" · "Terms" · "Privacy" (unchanged behavior/URLs).

### Responsiveness (prevents overflow / cut-off)

The added logo halo + trust row makes the screen taller. To guarantee everything is
reachable and nothing truncates on small devices (e.g. iPhone SE):

- Put the scrollable content (hero, benefits, plan cards) in a `ScrollView`.
- Pin the **CTA + trust row + footer** to the bottom via
  `.safeAreaInset(edge: .bottom)` so the primary action is always visible.

This is the canonical SwiftUI pattern and directly serves the "no nonsense / nothing
cut off" requirement.

## Data / Logic Changes

### `PlusProduct` (StoreManager.swift)
Add one field:
```swift
/// Honest savings vs. the monthly plan annualized (e.g. "SAVE 50%").
/// Populated for the yearly product only; nil when not computable.
let savingsText: String?
```

### `StoreManager` — savings computation
A **pure, unit-testable** helper computes the integer percentage. It is called when
building products in both the RevenueCat and StoreKit paths, using the raw `Decimal`
prices already available on `Product.price` / `package.storeProduct.price`:

```swift
/// Savings of the yearly plan vs the monthly plan annualized (×12),
/// falling back to weekly (×52) when there is no monthly plan.
/// Returns nil if not computable or <= 0.
static func savingsPercent(yearly: Decimal, monthly: Decimal?, weekly: Decimal?) -> Int?
```

Rules:
- Baseline = `monthly * 12` if a monthly price exists, else `weekly * 52`, else nil.
- `fraction = 1 - (yearly / baseline)`; percent = rounded to nearest Int.
- Return nil if baseline missing, yearly <= 0, or percent < 1 (never show "SAVE 0%").

`savingsText` = `"SAVE \(percent)%"` (localized) for the yearly product, nil otherwise.

Implementation note: collect raw prices into a `[productID: Decimal]` map before the
`.map` that builds `PlusProduct`s, so the yearly entry can read the monthly/weekly
prices. Both `loadStoreKitProducts()` and `plusProducts(from:)` get this treatment.

### `InlinePaywallStepView.swift`
Remove the privacy pill line (currently line 340):
```swift
trustPill(icon: "lock.shield.fill", label: String(localized: "Private. On-device."))
```
Leaving "Cancel anytime" + "3 days free". With two pills sharing the width, the
labels fit without scaling, so the "…" truncation disappears.

## What Stays Unchanged
- Product IDs, prices, App Store Connect / RevenueCat configuration.
- `purchase()`, `restorePurchases()`, `checkEntitlements()`, transaction listener.
- `subscribeButtonTitle` trial/subscribe logic (reused as-is).
- Terms / Privacy URLs and the Restore button.
- Hard-paywall presentation in `ContentView.swift` and all debug bypasses.
- The rest of the onboarding flow.

## Edge Cases
- **Products not loaded yet:** cards area empty, CTA disabled (current behavior kept).
- **No intro offer / not eligible:** CTA = "Subscribe"; no "3 days free" pill; yearly
  secondary line shows monthly-equivalent (`detail`).
- **`savingsText` nil** (e.g. only yearly available): yearly badge falls back to
  "Best Value".
- **Dynamic theme color:** every accent uses `AppColors.*`; default orange shown in
  mockups but the screen adapts to the user's selected color.
- **Dark mode:** background/cards use the adaptive `appBackground`/`appCard` color
  sets; text uses `.primary`/`.secondary`; logo container uses an adaptive fill.

## Testing
Tests live in `ios/calorietrackerTests` and use **Swift Testing** (`@Test`), matching
the existing suite.

- **Unit (TDD):** `StoreManager.savingsPercent(yearly:monthly:weekly:)`
  - yearly 29.99, monthly 4.99 → 50 (`1 - 29.99/59.88 ≈ 0.499`).
  - no monthly, weekly 1.99 → from 103.48 baseline (~71).
  - no monthly & no weekly → nil.
  - yearly priced ≥ baseline → nil (no negative/zero savings).
- **Manual / simulator:** verify on iPhone SE (smallest) and a large device, light
  and dark mode, with and without an intro offer, and with a non-default theme color;
  confirm no text truncation anywhere and the CTA is always visible.

## Files Touched
- `ios/calorietracker/Views/PaywallView.swift` — redesign.
- `ios/calorietracker/Stores/StoreManager.swift` — add `savingsText` + `savingsPercent`.
- `ios/calorietracker/Views/InlinePaywallStepView.swift` — remove privacy pill.
- `ios/calorietrackerTests/...` — add `savingsPercent` unit tests.
