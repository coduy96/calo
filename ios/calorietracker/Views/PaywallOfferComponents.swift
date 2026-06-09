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
