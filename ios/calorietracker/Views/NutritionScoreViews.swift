import SwiftUI

/// Visual surfaces for `NutritionScore`. Pure presentation — all logic lives in
/// `NutritionScoreEngine`.

// MARK: - Badge

struct NutritionScoreBadge: View {
    enum Size {
        case chip   // tiny letter circle for dense list rows
        case small  // letter + number, inline
        case large  // ring with number + grade, for headers/cards
    }

    let score: NutritionScore
    var size: Size = .small

    private var tint: Color {
        score.grade.color.opacity(score.isLimited ? 0.55 : 1)
    }

    var body: some View {
        switch size {
        case .chip: chip
        case .small: small
        case .large: large
        }
    }

    private var chip: some View {
        Text(score.grade.letter)
            .font(.system(size: 11, weight: .heavy, design: .rounded))
            .foregroundStyle(.white)
            .frame(width: 18, height: 18)
            .background(Circle().fill(tint))
            .accessibilityLabel(Text("Nutrition grade \(score.grade.letter)"))
    }

    private var small: some View {
        HStack(spacing: 8) {
            Text(score.grade.letter)
                .font(.system(size: 14, weight: .heavy, design: .rounded))
                .foregroundStyle(.white)
                .frame(width: 26, height: 26)
                .background(Circle().fill(tint))
            VStack(alignment: .leading, spacing: 0) {
                Text("\(score.value)")
                    .font(.system(.subheadline, design: .rounded, weight: .bold))
                    .contentTransition(.numericText())
                Text(score.grade.word)
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.secondary)
            }
        }
    }

    private var large: some View {
        ZStack {
            ActivityRingView(
                progress: Double(score.value) / 100,
                ringWidth: 7,
                gradientColors: [tint, tint.opacity(0.6)]
            )
            VStack(spacing: -2) {
                Text("\(score.value)")
                    .font(.system(size: 26, weight: .bold, design: .rounded))
                    .foregroundStyle(.primary)
                    .contentTransition(.numericText())
                Text(score.grade.letter)
                    .font(.system(.caption, design: .rounded, weight: .heavy))
                    .foregroundStyle(tint)
            }
        }
        .frame(width: 78, height: 78)
        .accessibilityElement(children: .ignore)
        .accessibilityLabel(Text("Nutrition score \(score.value), grade \(score.grade.letter)"))
    }
}

// MARK: - Breakdown

struct NutritionScoreBreakdown: View {
    let score: NutritionScore

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            ForEach(score.positives) { contributorRow($0, positive: true) }
            ForEach(score.negatives) { contributorRow($0, positive: false) }

            if score.positives.isEmpty && score.negatives.isEmpty {
                Text("No standout nutrients.")
                    .font(.system(.footnote, design: .rounded))
                    .foregroundStyle(.secondary)
            }

            if score.isLimited {
                Label("Based on limited data", systemImage: "info.circle")
                    .font(.system(.caption2, design: .rounded))
                    .foregroundStyle(.tertiary)
                    .padding(.top, 2)
            }
        }
    }

    private func contributorRow(_ contributor: NutritionContributor, positive: Bool) -> some View {
        HStack(spacing: 8) {
            Image(systemName: positive ? "plus.circle.fill" : "minus.circle.fill")
                .font(.footnote)
                .foregroundStyle(positive ? Color(hex: 0x34C759) : Color(hex: 0xFF3B30))
            Text(contributor.label)
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.primary)
            Spacer(minLength: 0)
        }
    }
}

// MARK: - Food review/edit section

/// A List `Section` showing the food's grade badge + the "why" breakdown.
/// Used on both the review-after-logging and edit screens.
struct FoodNutritionScoreSection: View {
    let score: NutritionScore

    var body: some View {
        Section("Nutrition Score") {
            HStack(spacing: 16) {
                NutritionScoreBadge(score: score, size: .large)
                VStack(alignment: .leading, spacing: 4) {
                    Text(score.grade.word)
                        .font(.system(.title3, design: .rounded, weight: .bold))
                        .foregroundStyle(score.grade.color)
                    Text("Food quality grade")
                        .font(.system(.caption, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Spacer(minLength: 0)
            }
            NutritionScoreBreakdown(score: score)
        }
    }
}

