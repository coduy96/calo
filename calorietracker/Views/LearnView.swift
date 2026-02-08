import SwiftUI

// MARK: - Learn View
struct LearnView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
                    LearnHeaderView()
                        .padding(.horizontal)

                    ForEach(Article.allArticles) { article in
                        NavigationLink(destination: ArticleDetailView(article: article)) {
                            ArticleCardView(article: article)
                        }
                        .buttonStyle(.plain)
                        .padding(.horizontal)
                    }
                }
                .padding(.vertical)
            }
            .background(AppColors.appBackground)
            .navigationTitle("Learn")
        }
    }
}

// MARK: - Header
struct LearnHeaderView: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            Text("Nutrition & Wellness")
                .font(.system(.title2, design: .rounded, weight: .bold))
            Text("Evidence-based articles to help you understand your body and make better choices.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding()
        .background(AppColors.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Article Card
struct ArticleCardView: View {
    let article: Article

    var body: some View {
        HStack(spacing: 14) {
            // Gradient icon
            Image(systemName: article.icon)
                .font(.title2)
                .foregroundStyle(.white)
                .frame(width: 52, height: 52)
                .background(
                    LinearGradient(
                        colors: article.category.gradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
                .clipShape(RoundedRectangle(cornerRadius: 12))

            VStack(alignment: .leading, spacing: 4) {
                Text(article.title)
                    .font(.system(.subheadline, design: .rounded, weight: .semibold))
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                Text(article.summary)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(2)
                    .multilineTextAlignment(.leading)

                HStack(spacing: 8) {
                    Text("\(article.readingTimeMinutes) min read")
                        .font(.caption2)
                        .foregroundStyle(.tertiary)

                    Text(article.category.rawValue)
                        .font(.caption2)
                        .fontWeight(.medium)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(article.category.color.opacity(0.15))
                        .foregroundStyle(article.category.color)
                        .clipShape(Capsule())
                }
            }

            Spacer()

            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .padding()
        .background(AppColors.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }
}

// MARK: - Article Detail
struct ArticleDetailView: View {
    let article: Article

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero header
                VStack(spacing: 12) {
                    Image(systemName: article.icon)
                        .font(.system(size: 44))
                        .foregroundStyle(
                            LinearGradient(
                                colors: article.category.gradient,
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )

                    Text(article.title)
                        .font(.system(.title2, design: .rounded, weight: .bold))
                        .multilineTextAlignment(.center)

                    HStack(spacing: 12) {
                        Label("\(article.readingTimeMinutes) min read", systemImage: "clock")
                            .font(.caption)
                            .foregroundStyle(.secondary)

                        Text(article.category.rawValue)
                            .font(.caption)
                            .fontWeight(.medium)
                            .padding(.horizontal, 8)
                            .padding(.vertical, 3)
                            .background(article.category.color.opacity(0.15))
                            .foregroundStyle(article.category.color)
                            .clipShape(Capsule())
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(AppColors.appCard)
                .clipShape(RoundedRectangle(cornerRadius: 16))

                // Content paragraphs
                ForEach(Array(article.contentParagraphs.enumerated()), id: \.offset) { _, paragraph in
                    let trimmed = paragraph.trimmingCharacters(in: .whitespacesAndNewlines)
                    if trimmed.hasPrefix("## ") {
                        Text(String(trimmed.dropFirst(3)))
                            .font(.system(.headline, design: .rounded, weight: .bold))
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                            .padding(.top, 4)
                    } else {
                        Text(trimmed)
                            .font(.system(.body, design: .rounded))
                            .foregroundStyle(.secondary)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .padding(.horizontal)
                    }
                }
            }
            .padding()
        }
        .background(AppColors.appBackground)
        .navigationBarTitleDisplayMode(.inline)
    }
}
