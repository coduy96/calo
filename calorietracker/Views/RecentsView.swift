import SwiftUI

struct RecentsView: View {
    let logDate: Date

    @Environment(FoodStore.self) private var foodStore
    @Environment(\.dismiss) private var dismiss

    @AppStorage("lastRecentsSegment") private var lastSegment: String = RecentsSegment.recents.rawValue

    @State private var segment: RecentsSegment = .recents

    private enum RecentsSegment: String, CaseIterable {
        case recents = "Recents"
        case frequent = "Frequent"
        case favorites = "Favorites"
    }

    private var recentItems: [FoodEntry] {
        foodStore.recentEntries(limit: 50)
    }

    private var frequentItems: [FrequentFoodGroup] {
        foodStore.frequentGroups()
    }

    var body: some View {
        NavigationStack {
            List {
                Section {
                    Picker("View", selection: $segment) {
                        ForEach(RecentsSegment.allCases, id: \.self) { mode in
                            Text(mode.rawValue).tag(mode)
                        }
                    }
                    .pickerStyle(.segmented)
                    .listRowBackground(Color.clear)
                }

                switch segment {
                case .recents:
                    if recentItems.isEmpty {
                        emptySection(icon: "clock", message: "No foods logged yet")
                    } else {
                        Section {
                            ForEach(recentItems) { entry in
                                SavedMealRow(entry: entry, isFavorite: foodStore.isFavorite(entry))
                                    .listRowBackground(AppColors.appCard)
                                    .contentShape(Rectangle())
                                    .onTapGesture { logEntry(entry) }
                                    .swipeActions(edge: .trailing) {
                                        Button {
                                            withAnimation { foodStore.toggleFavorite(entry) }
                                        } label: {
                                            Label(foodStore.isFavorite(entry) ? "Unfavorite" : "Favorite", systemImage: foodStore.isFavorite(entry) ? "heart.slash.fill" : "heart.fill")
                                        }
                                        .tint(AppColors.calorie)
                                    }
                            }
                        }
                    }

                case .frequent:
                    if frequentItems.isEmpty {
                        emptySection(icon: "repeat", message: "No foods logged yet")
                    } else {
                        Section {
                            ForEach(frequentItems) { group in
                                SavedMealRow(entry: group.template, isFavorite: foodStore.isFavorite(group.template), subtitle: "\(group.count)× logged")
                                    .listRowBackground(AppColors.appCard)
                                    .contentShape(Rectangle())
                                    .onTapGesture { logEntry(group.template) }
                                    .swipeActions(edge: .trailing) {
                                        Button {
                                            withAnimation { foodStore.toggleFavorite(group.template) }
                                        } label: {
                                            Label(foodStore.isFavorite(group.template) ? "Unfavorite" : "Favorite", systemImage: foodStore.isFavorite(group.template) ? "heart.slash.fill" : "heart.fill")
                                        }
                                        .tint(AppColors.calorie)
                                    }
                            }
                        }
                    }

                case .favorites:
                    if foodStore.favorites.isEmpty {
                        emptySection(icon: "heart", message: "No favorites yet\nSwipe left on any food to add it")
                    } else {
                        Section {
                            ForEach(foodStore.favorites) { entry in
                                SavedMealRow(entry: entry, isFavorite: true)
                                    .listRowBackground(AppColors.appCard)
                                    .contentShape(Rectangle())
                                    .onTapGesture { logEntry(entry) }
                                    .swipeActions(edge: .trailing) {
                                        Button(role: .destructive) {
                                            withAnimation { foodStore.toggleFavorite(entry) }
                                        } label: {
                                            Label("Remove", systemImage: "heart.slash.fill")
                                        }
                                    }
                            }
                            .onMove { from, to in
                                foodStore.moveFavorite(from: from, to: to)
                            }
                        }
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(AppColors.appBackground)
            .navigationTitle("Saved Meals")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Done") { dismiss() }
                }
                if segment == .favorites && !foodStore.favorites.isEmpty {
                    ToolbarItem(placement: .topBarTrailing) {
                        EditButton()
                    }
                }
            }
            .onAppear {
                if let saved = RecentsSegment(rawValue: lastSegment) {
                    segment = saved
                }
            }
            .onChange(of: segment) { _, newValue in
                lastSegment = newValue.rawValue
            }
        }
    }

    private func logEntry(_ entry: FoodEntry) {
        foodStore.addEntry(entry.duplicatedForLogging(at: logDate))
        dismiss()
    }

    private func emptySection(icon: String, message: String) -> some View {
        Section {
            VStack(spacing: 12) {
                Image(systemName: icon)
                    .font(.system(size: 32))
                    .foregroundStyle(AppColors.calorie.opacity(0.4))
                Text(message)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 24)
            .listRowBackground(AppColors.appCard)
        }
    }
}

// MARK: - Saved Meal Row

private struct SavedMealRow: View {
    let entry: FoodEntry
    let isFavorite: Bool
    var subtitle: String? = nil

    var body: some View {
        HStack(spacing: 12) {
            // Thumbnail
            if let imageData = entry.imageData, let uiImage = UIImage(data: imageData) {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFill()
                    .frame(width: 56, height: 56)
                    .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                    .overlay(
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(AppColors.calorie.opacity(0.15), lineWidth: 1)
                    )
            } else if let emoji = entry.emoji {
                Text(emoji)
                    .font(.system(size: 28))
                    .frame(width: 56, height: 56)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            } else {
                Image(systemName: "fork.knife")
                    .font(.title3)
                    .foregroundStyle(AppColors.calorie)
                    .frame(width: 56, height: 56)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12, style: .continuous))
            }

            // Info
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 4) {
                    Text(entry.name)
                        .font(.system(.body, design: .rounded, weight: .medium))
                        .lineLimit(1)
                    if isFavorite {
                        Image(systemName: "heart.fill")
                            .font(.caption2)
                            .foregroundStyle(AppColors.calorie)
                    }
                }

                HStack(spacing: 6) {
                    Text("\(entry.calories) kcal")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                        .foregroundStyle(AppColors.calorie)

                    if let subtitle {
                        Text("·")
                            .foregroundStyle(.tertiary)
                        Text(subtitle)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.secondary)
                    }
                }

                HStack(spacing: 8) {
                    MacroTag(label: "P", value: entry.protein)
                    MacroTag(label: "C", value: entry.carbs)
                    MacroTag(label: "F", value: entry.fat)
                }
            }

            Spacer(minLength: 0)

            // Log button
            Image(systemName: "plus.circle.fill")
                .font(.title3)
                .foregroundStyle(AppColors.calorie)
        }
        .padding(.vertical, 4)
    }
}

// MARK: - Macro Tag

private struct MacroTag: View {
    let label: String
    let value: Int

    var body: some View {
        Text("\(label) \(value)g")
            .font(.system(.caption2, design: .rounded, weight: .medium))
            .foregroundStyle(.secondary)
            .padding(.horizontal, 6)
            .padding(.vertical, 2)
            .background(AppColors.calorie.opacity(0.08), in: Capsule())
    }
}
