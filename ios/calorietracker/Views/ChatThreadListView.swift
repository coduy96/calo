import SwiftUI

/// "Coach" tab root — shows a list of past chat threads, supports search, swipe-to-delete,
/// rename, and creating a new chat. Each row pushes into ChatView where the actual
/// conversation happens (and where the tab bar auto-hides).
struct ChatThreadListView: View {
    @Environment(ChatStore.self) private var chatStore

    @State private var searchText = ""
    @State private var navigationPath = NavigationPath()
    @State private var renameTarget: ChatThread?
    @State private var renameDraft = ""

    private var filteredThreads: [ChatThread] {
        let all = chatStore.visibleThreads
        let needle = searchText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !needle.isEmpty else { return all }
        let lower = needle.lowercased()
        return all.filter { thread in
            if thread.title.lowercased().contains(lower) { return true }
            return thread.messages.contains { $0.content.lowercased().contains(lower) }
        }
    }

    var body: some View {
        NavigationStack(path: $navigationPath) {
            Group {
                if chatStore.visibleThreads.isEmpty {
                    emptyState
                } else if filteredThreads.isEmpty {
                    noResultsState
                } else {
                    threadList
                }
            }
            .background(AppColors.appBackground)
            .navigationTitle("AI Coach")
            .navigationBarTitleDisplayMode(.inline)
            .searchable(
                text: $searchText,
                placement: .navigationBarDrawer(displayMode: .always),
                prompt: Text("Search chats")
            )
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        startNewChat()
                    } label: {
                        Image(systemName: "square.and.pencil")
                            .foregroundStyle(AppColors.calorie)
                    }
                    .accessibilityLabel("New Chat")
                }
            }
            .navigationDestination(for: UUID.self) { threadID in
                ChatView(threadID: threadID)
            }
            .alert(
                "Rename Chat",
                isPresented: Binding(
                    get: { renameTarget != nil },
                    set: { if !$0 { renameTarget = nil } }
                )
            ) {
                TextField("Title", text: $renameDraft)
                    .textInputAutocapitalization(.sentences)
                Button("Cancel", role: .cancel) {
                    renameTarget = nil
                }
                Button("Save") {
                    if let target = renameTarget {
                        chatStore.rename(threadID: target.id, to: renameDraft)
                    }
                    renameTarget = nil
                }
            }
        }
    }

    // MARK: - Sections

    private var threadList: some View {
        List {
            ForEach(filteredThreads) { thread in
                Button {
                    navigationPath.append(thread.id)
                } label: {
                    ChatThreadRow(thread: thread)
                }
                .buttonStyle(.plain)
                .listRowBackground(AppColors.appCard)
                .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                    Button(role: .destructive) {
                        withAnimation { chatStore.delete(threadID: thread.id) }
                    } label: {
                        Label("Delete", systemImage: "trash.fill")
                    }
                }
                .swipeActions(edge: .leading) {
                    Button {
                        renameDraft = thread.title
                        renameTarget = thread
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    .tint(AppColors.calorie)
                }
                .contextMenu {
                    Button {
                        renameDraft = thread.title
                        renameTarget = thread
                    } label: {
                        Label("Rename", systemImage: "pencil")
                    }
                    Button(role: .destructive) {
                        chatStore.delete(threadID: thread.id)
                    } label: {
                        Label("Delete", systemImage: "trash")
                    }
                }
            }
        }
        .listStyle(.insetGrouped)
        .scrollContentBackground(.hidden)
        .background(AppColors.appBackground)
    }

    private var emptyState: some View {
        VStack(spacing: 16) {
            Spacer()
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 108, height: 108)
                    .overlay(
                        Circle().stroke(
                            LinearGradient(
                                colors: [Color.white.opacity(0.35), Color.white.opacity(0.05)],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            ),
                            lineWidth: 0.8
                        )
                    )
                    .shadow(color: AppColors.calorie.opacity(0.18), radius: 24, x: 0, y: 10)
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 44))
                    .foregroundStyle(
                        LinearGradient(colors: AppColors.calorieGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }
            Text("Ask your Coach")
                .font(.system(.title2, design: .rounded, weight: .semibold))
            Text("Your coach can see your weight history, calorie log, and goals. Ask about expected weight, what to eat, or how to hit your target.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)

            Button {
                startNewChat()
            } label: {
                HStack(spacing: 8) {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 15, weight: .semibold))
                    Text("Start your first chat")
                        .font(.system(.subheadline, design: .rounded, weight: .semibold))
                }
                .foregroundStyle(.white)
                .padding(.horizontal, 22)
                .padding(.vertical, 12)
                .background(
                    LinearGradient(
                        colors: AppColors.calorieGradient,
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    ),
                    in: Capsule(style: .continuous)
                )
                .overlay(
                    Capsule(style: .continuous)
                        .stroke(Color.white.opacity(0.25), lineWidth: 0.6)
                )
                .shadow(color: AppColors.calorie.opacity(0.35), radius: 10, x: 0, y: 5)
            }
            .buttonStyle(.plain)
            .padding(.top, 8)

            Spacer()
        }
    }

    private var noResultsState: some View {
        VStack(spacing: 10) {
            Spacer()
            Image(systemName: "magnifyingglass")
                .font(.system(size: 38))
                .foregroundStyle(.secondary)
            Text("No matching chats")
                .font(.system(.subheadline, design: .rounded, weight: .medium))
                .foregroundStyle(.secondary)
            Spacer()
        }
    }

    // MARK: - Actions

    private func startNewChat() {
        let draft = chatStore.createDraftThread()
        navigationPath.append(draft.id)
    }
}

// MARK: - Row

private struct ChatThreadRow: View {
    let thread: ChatThread

    private static let timeFormatter: RelativeDateTimeFormatter = {
        let f = RelativeDateTimeFormatter()
        f.unitsStyle = .abbreviated
        return f
    }()

    private var titleText: String {
        thread.title.isEmpty ? "New Chat" : thread.title
    }

    private var previewText: String {
        let raw = thread.lastMessagePreview
            .replacingOccurrences(of: "\n", with: " ")
            .trimmingCharacters(in: .whitespacesAndNewlines)
        return raw.isEmpty ? " " : raw
    }

    var body: some View {
        HStack(alignment: .top, spacing: 12) {
            ZStack {
                Circle()
                    .fill(.ultraThinMaterial)
                    .frame(width: 40, height: 40)
                    .overlay(Circle().stroke(Color.white.opacity(0.15), lineWidth: 0.5))
                Image(systemName: "bubble.left.and.bubble.right.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundStyle(
                        LinearGradient(colors: AppColors.calorieGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                    )
            }

            VStack(alignment: .leading, spacing: 3) {
                Text(titleText)
                    .font(.system(.body, design: .rounded, weight: .semibold))
                    .lineLimit(1)
                    .truncationMode(.tail)
                Text(previewText)
                    .font(.system(.subheadline, design: .rounded))
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
                    .truncationMode(.tail)
            }

            Spacer(minLength: 6)

            Text(Self.timeFormatter.localizedString(for: thread.updatedAt, relativeTo: .now))
                .font(.system(.caption, design: .rounded))
                .foregroundStyle(.tertiary)
        }
        .padding(.vertical, 4)
        .contentShape(Rectangle())
    }
}
