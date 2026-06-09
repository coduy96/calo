# Paywall Enhancement — Honest Hormozi Offer

Date: 2026-06-09
Status: Approved design, pending implementation plan

## Context

Voidpen ships two paywalls, both already logo-first and honest (no dark
patterns per the project's standing UI rule):

- `ios/calorietracker/Views/PaywallView.swift` — the **hard paywall**: the
  app gate returning / unsubscribed users hit. Logo → 4 feature rows → 3 plan
  cards → subscribe → trust pills → Restore/Terms/Privacy.
- `ios/calorietracker/Views/InlinePaywallStepView.swift` — the **onboarding
  paywall** at the end of the 12-screen flow. Already more persuasive:
  personalized headline, plan-recap card, a red-X "Walk away and this resets"
  loss-aversion section, per-day pricing.

Product/price data comes from `ios/calorietracker/Stores/StoreManager.swift`
via `PlusProduct`, which already exposes everything we need: `displayPrice`,
per-day price (`pricePerDayText`, yearly only), honest `savingsText`
("SAVE X%", yearly only), 3-day trial copy (`introOfferCopy`), and the
yearly's real monthly-equivalent (`detail` = "$X/mo").

The goal: apply Alex Hormozi's *$100M Offers* "make them feel stupid saying
no" principle — but the **honest** version, which Hormozi himself defines as
*overwhelming value + total risk reversal*, NOT pressure or trickery. This
aligns with, rather than violates, the project's no-dark-patterns rule.

## Decisions (locked during brainstorming)

| Decision | Choice |
|---|---|
| Intensity | **Honest Hormozi** — value + risk reversal, zero dark patterns |
| Scope | **Both** paywalls |
| Social proof | **None** — app has no honest numbers yet; we fabricate nothing |
| Value framing | **Real-world cost comparison** ("what this replaces") |
| Anchor numbers | **Exact: $90 / $30 / $10** (most effective + defensible market floors), stored as editable constants |
| Hard-paywall headline | **"Hit your goal. No guesswork."** |
| Pricing / tier lineup | **No changes** — presentation and copy only |

## Goals

1. Raise conversion on both paywalls using legitimate value + risk-reversal levers.
2. Make declining feel irrational because the value/price gap is obvious and the trial is risk-free — not because the user is pressured or guilt-tripped.
3. Keep every on-screen number real and every claim verifiable.

## Non-goals

- No pricing, tier, or product-lineup changes.
- No countdown timers, fake scarcity, fake/borrowed social proof, pre-checked
  traps, hidden close buttons, or guilt copy.
- No "money-back guarantee" claim (Apple owns refunds; the free trial is the
  honest risk reversal).
- No backend, StoreManager purchase-logic, or RevenueCat changes.

## The three new levers

### Lever 1 — Value anchor: "What this replaces"

A card anchoring Voidpen's price against the real-world cost of the same
outcome. All true market floors.

```
What this replaces
  1:1 nutritionist          $90 / visit
  Macro-coaching app        $30 / mo
  Premium calorie tracker   $10 / mo
  ─────────────────────────────────
  Voidpen Plus — all of it     from $X / mo
```

- `$X` = the yearly plan's real monthly-equivalent (`yearlyProduct.detail`,
  already "$X/mo"). If yearly is unavailable, fall back to
  `monthlyProduct.displayPrice` and drop the "from".
- The three comparison rows are **editable constants** (label + price string)
  defined in the new shared component, so they can be tuned without touching
  layout code.
- Rendered with the existing design system: `AppColors.appCard` background,
  muted secondary text for the comparison rows, the Voidpen line emphasized
  with `AppColors.calorie` / the calorie gradient.

### Lever 2 — Risk-reversal line

A single bold line directly above the subscribe button:

> **3 days free. Cancel in 2 taps. $0 if it's not for you.**

This is the real guarantee. Shown only when the selected product is
trial-eligible (`selectedProduct?.introOfferCopy != nil`); when not eligible,
fall back to **"Cancel anytime in 2 taps."**

### Lever 3 — Per-day anchor on the yearly card

Surface the already-computed `pricePerDayText` on the yearly plan card in the
hard paywall: **"Less than $0.27/day"** (reads as "less than a coffee"). The
onboarding paywall already does this — this brings the hard paywall to parity.

## Hard paywall changes (`PaywallView.swift`)

New top → bottom order:

1. Logo + `VOIDPEN PLUS` eyebrow — *keep*
2. Headline → **"Hit your goal. No guesswork."** *(was "Everything unlocked")*
3. Feature rows, reframed to outcomes:
   - "Snap or say any meal — macros in seconds"
   - "A personal AI coach that learns your body"
   - "Scan any label, get the real numbers"
   - "See where your weight is actually heading"
4. **NEW: "What this replaces" value card** (Lever 1)
5. Plan cards — *keep*; add per-day anchor to yearly card (Lever 3); yearly
   stays highlighted with `SAVE X%`
6. **NEW: risk-reversal line** (Lever 2), in the pinned bottom bar above the button
7. Subscribe CTA → **"Start My 3-Day Free Trial"** (trial-eligible) /
   **"Unlock Everything"** (not eligible) — *keep styling*
8. Trust pills + Restore/Terms/Privacy — *keep (App Store required)*

## Onboarding paywall changes (`InlinePaywallStepView.swift`)

Already strong; lighter touch to avoid bloat:

1. Personalized headline, plan-recap card, "Walk away and this resets" loss
   section — *all keep* (honest, personalized loss-aversion)
2. **NEW: compact value anchor** — a single tight line instead of the full
   card: *"Cheaper than a single nutritionist visit — for a whole month."*
   Placed after the loss section.
3. **NEW: risk-reversal line** (Lever 2) above the existing CTA
4. Tier cards (per-day anchor already present), trust strip, CTA + fine print,
   footer — *keep*

## New shared component

Add one new file (Xcode synchronized folder auto-includes it — no pbxproj
edit needed):

`ios/calorietracker/Views/PaywallOfferComponents.swift` containing:

- `ReplacedCost` — `struct { let label: String; let price: String }` plus a
  `static let defaults: [ReplacedCost]` holding the $90/$30/$10 lines (the
  editable constants).
- `ReplacesValueCard` — the full Lever 1 card; takes the Voidpen "from $X/mo"
  string and the `[ReplacedCost]` rows.
- `RiskReversalLine` — the Lever 2 line; takes a `trialEligible: Bool` and
  renders the matching copy.

Both paywalls consume these. The onboarding paywall uses `RiskReversalLine`
plus its own compact one-line anchor (not the full card).

## Styling

- Reuse `AppColors` (`appCard`, `calorie`, `calorieGradient`, `appBackground`)
  and `.system(..., design: .rounded)` fonts to match existing paywall styling.
- New strings use `String(localized:)` for parity with the localized app.
- No truncating ellipses; use `fixedSize`/`minimumScaleFactor` as the existing
  rows do.

## Data dependencies (no changes required)

All sourced from existing `PlusProduct` fields: `displayPrice`,
`pricePerDayText`, `savingsText`, `introOfferCopy`, `detail`. The
"from $X/mo" Voidpen line reuses `yearlyProduct.detail`.

## What we are explicitly NOT doing

No countdown timers, no fake scarcity, no fabricated social proof, no
pre-checked upsells, no hidden/relocated close, no guilt copy, no
money-back-guarantee claim. Pricing and tiers untouched.

## Testing & verification

- Build the app for the simulator (zero errors/warnings) via XcodeBuildMCP.
- Launch and screenshot both paywalls (hard gate + onboarding step) to confirm
  layout, that real prices/savings/per-day/trial copy render, and that the new
  value card + risk-reversal line read correctly with live StoreKit data.
- Verify the no-trial fallback copy path (risk-reversal line + CTA) by
  reasoning through `introOfferCopy == nil`.
- Confirm Restore/Terms/Privacy remain present and tappable.

## Out of scope / future

- Real social proof (ratings/user count/testimonials) once honest numbers exist.
- A/B testing the variants via RevenueCat experiments.
- Any aggressive/"full pressure" tactics (explicitly rejected).
