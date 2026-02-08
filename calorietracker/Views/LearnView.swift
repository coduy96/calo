import SwiftUI

// MARK: - Learn View
struct LearnView: View {
    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 16) {
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

// MARK: - Article Card
struct ArticleCardView: View {
    let article: Article

    var body: some View {
        VStack(spacing: 0) {
            // Image thumbnail
            Color.clear
                .frame(height: 180)
                .overlay {
                    AsyncImage(url: URL(string: article.imageURL)) { phase in
                        switch phase {
                        case .success(let image):
                            image
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                        case .failure:
                            imagePlaceholder
                        case .empty:
                            imagePlaceholder
                                .overlay(ProgressView().tint(.white))
                        @unknown default:
                            imagePlaceholder
                        }
                    }
                }
                .clipped()

            // Article info
            VStack(alignment: .leading, spacing: 6) {
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
                    Label("\(article.readingTimeMinutes) min read", systemImage: "clock")
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
            .padding()
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .background(AppColors.appCard)
        .clipShape(RoundedRectangle(cornerRadius: 16))
    }

    private var imagePlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: article.category.gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: article.icon)
                .font(.system(size: 40))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}

// MARK: - Article Detail
struct ArticleDetailView: View {
    let article: Article

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Hero header with image
                VStack(spacing: 0) {
                    Color.clear
                        .frame(height: 220)
                        .overlay {
                            AsyncImage(url: URL(string: article.imageURL)) { phase in
                                switch phase {
                                case .success(let image):
                                    image
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                case .failure:
                                    detailImagePlaceholder
                                case .empty:
                                    detailImagePlaceholder
                                        .overlay(ProgressView().tint(.white))
                                @unknown default:
                                    detailImagePlaceholder
                                }
                            }
                        }
                        .clipped()

                    VStack(spacing: 8) {
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
                }
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

    private var detailImagePlaceholder: some View {
        ZStack {
            LinearGradient(
                colors: article.category.gradient,
                startPoint: .topLeading,
                endPoint: .bottomTrailing
            )
            Image(systemName: article.icon)
                .font(.system(size: 48))
                .foregroundStyle(.white.opacity(0.7))
        }
    }
}
