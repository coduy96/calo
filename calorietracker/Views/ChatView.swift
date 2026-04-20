import SwiftUI

/// "Coach" tab — a persistent AI conversation that has access to the user's profile,
/// weight history, food log, and computed forecast. Handles multi-turn chat with memory
/// (saved locally), a reset button, and context-aware quick-reply prompt chips.
struct ChatView: View {
    @Environment(ChatStore.self) private var chatStore
    @Environment(ProfileStore.self) private var profileStore
    @Environment(WeightStore.self) private var weightStore
    @Environment(FoodStore.self) private var foodStore
    @AppStorage("useMetric") private var useMetric = false

    @State private var draft = ""
    @State private var isSending = false
    @State private var errorMessage: String?
    @State private var showResetConfirmation = false
    @FocusState private var isInputFocused: Bool

    private var userProfile: UserProfile { profileStore.profile }
    private var messages: [ChatMessage] { chatStore.messages }

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if messages.isEmpty {
                    emptyState
                } else {
                    messageList
                }

                promptChips

                inputBar
            }
            .background(
                AppColors.appBackground
                    .contentShape(Rectangle())
                    .onTapGesture { isInputFocused = false }
            )
            .navigationTitle("Coach")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        if !messages.isEmpty { showResetConfirmation = true }
                    } label: {
                        Image(systemName: "arrow.counterclockwise")
                            .foregroundStyle(messages.isEmpty ? Color.secondary : AppColors.calorie)
                    }
                    .disabled(messages.isEmpty)
                }
            }
            .alert("Reset Chat", isPresented: $showResetConfirmation) {
                Button("Cancel", role: .cancel) { }
                Button("Reset", role: .destructive) {
                    chatStore.reset()
                    errorMessage = nil
                }
            } message: {
                Text("Clear all messages and start fresh? This can't be undone.")
            }
        }
    }

    // MARK: - Sections

    private var emptyState: some View {
        VStack(spacing: 12) {
            Spacer()
            Image(systemName: "bubble.left.and.bubble.right.fill")
                .font(.system(size: 48))
                .foregroundStyle(
                    LinearGradient(colors: AppColors.calorieGradient, startPoint: .topLeading, endPoint: .bottomTrailing)
                )
            Text("Ask your Coach")
                .font(.system(.title2, design: .rounded, weight: .semibold))
            Text("Your coach can see your weight history, calorie log, and goals. Ask about expected weight, what to eat, or how to hit your target.")
                .font(.system(.subheadline, design: .rounded))
                .foregroundStyle(.secondary)
                .multilineTextAlignment(.center)
                .padding(.horizontal, 32)
            Spacer()
        }
    }

    private var messageList: some View {
        ScrollViewReader { proxy in
            ScrollView {
                LazyVStack(spacing: 10) {
                    ForEach(messages) { msg in
                        MessageBubble(message: msg)
                            .id(msg.id)
                    }
                    if isSending {
                        HStack {
                            TypingIndicator()
                                .padding(.horizontal, 14)
                                .padding(.vertical, 10)
                                .background(AppColors.appCard, in: RoundedRectangle(cornerRadius: 14))
                            Spacer()
                        }
                        .padding(.horizontal)
                        .id("typing")
                    }
                    if let err = errorMessage {
                        Text(err)
                            .font(.system(.caption, design: .rounded))
                            .foregroundStyle(.red)
                            .padding(.horizontal)
                    }
                }
                .padding(.vertical, 12)
            }
            .scrollDismissesKeyboard(.interactively)
            .onChange(of: messages.count) { _, _ in
                withAnimation { proxy.scrollTo(messages.last?.id, anchor: .bottom) }
            }
            .onChange(of: isSending) { _, sending in
                if sending { withAnimation { proxy.scrollTo("typing", anchor: .bottom) } }
            }
        }
    }

    /// Context-aware suggested prompts — pick a different set based on goal to keep them relevant.
    private var promptChips: some View {
        let chips: [String] = {
            switch userProfile.goal {
            case .lose:
                return [
                    "What's my expected weight in 30 days?",
                    "How do I lose weight faster safely?",
                    "Am I eating too much?",
                    "What should I eat for dinner?",
                ]
            case .gain:
                return [
                    "What's my expected weight in 30 days?",
                    "How do I gain weight healthily?",
                    "Am I eating enough?",
                    "High-protein foods I can add?",
                ]
            case .maintain:
                return [
                    "Am I holding my weight?",
                    "What's my average intake?",
                    "Macro suggestions?",
                    "How's my trend?",
                ]
            }
        }()

        return ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                ForEach(chips, id: \.self) { chip in
                    Button {
                        draft = chip
                        send()
                    } label: {
                        Text(chip)
                            .font(.system(.footnote, design: .rounded, weight: .medium))
                            .padding(.horizontal, 12)
                            .padding(.vertical, 8)
                            .background(AppColors.calorie.opacity(0.12), in: Capsule())
                            .foregroundStyle(AppColors.calorie)
                    }
                    .buttonStyle(.plain)
                    .disabled(isSending)
                }
            }
            .padding(.horizontal)
            .padding(.vertical, 8)
        }
    }

    private var inputBar: some View {
        HStack(spacing: 10) {
            TextField("Ask Coach…", text: $draft, axis: .vertical)
                .lineLimit(1...5)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(AppColors.appCard, in: RoundedRectangle(cornerRadius: 20))
                .focused($isInputFocused)
                .disabled(isSending)

            Button {
                send()
            } label: {
                Image(systemName: "arrow.up.circle.fill")
                    .font(.system(size: 32))
                    .foregroundStyle(
                        canSend
                            ? AnyShapeStyle(LinearGradient(colors: AppColors.calorieGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                            : AnyShapeStyle(Color.secondary)
                    )
            }
            .disabled(!canSend)
        }
        .padding(.horizontal)
        .padding(.bottom, 8)
        .padding(.top, 4)
    }

    private var canSend: Bool {
        !isSending && !draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    // MARK: - Send

    private func send() {
        let text = draft.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !text.isEmpty, !isSending else { return }

        chatStore.append(ChatMessage(role: .user, content: text))
        draft = ""
        errorMessage = nil
        isSending = true
        let historyForCall = chatStore.contextMessages().dropLast()  // exclude the user msg we just appended

        Task {
            defer { isSending = false }
            do {
                let reply = try await ChatService.sendMessage(
                    history: Array(historyForCall),
                    newUserMessage: text,
                    profile: userProfile,
                    weights: weightStore.entries,
                    foods: foodStore.entries,
                    useMetric: useMetric
                )
                chatStore.append(ChatMessage(role: .assistant, content: reply))
            } catch {
                errorMessage = (error as? LocalizedError)?.errorDescription ?? error.localizedDescription
            }
        }
    }
}

// MARK: - Supporting views

private struct MessageBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .top) {
            if message.role == .assistant {
                Image(systemName: "sparkles")
                    .font(.system(size: 12, weight: .semibold))
                    .foregroundStyle(AppColors.calorie)
                    .padding(.top, 14)
            } else {
                Spacer(minLength: 40)
            }
            Text(message.content)
                .font(.system(.body, design: .rounded))
                .textSelection(.enabled)
                .padding(.horizontal, 14)
                .padding(.vertical, 10)
                .background(
                    message.role == .user
                        ? AnyShapeStyle(LinearGradient(colors: AppColors.calorieGradient, startPoint: .topLeading, endPoint: .bottomTrailing))
                        : AnyShapeStyle(AppColors.appCard),
                    in: RoundedRectangle(cornerRadius: 16)
                )
                .foregroundStyle(message.role == .user ? .white : .primary)
                .fixedSize(horizontal: false, vertical: true)
            if message.role == .user {
                // no trailing icon for user
            } else {
                Spacer(minLength: 40)
            }
        }
        .padding(.horizontal)
    }
}

private struct TypingIndicator: View {
    @State private var phase = 0
    var body: some View {
        HStack(spacing: 4) {
            ForEach(0..<3) { i in
                Circle()
                    .fill(AppColors.calorie)
                    .frame(width: 6, height: 6)
                    .opacity(phase == i ? 1 : 0.3)
            }
        }
        .onAppear {
            Timer.scheduledTimer(withTimeInterval: 0.35, repeats: true) { _ in
                phase = (phase + 1) % 3
            }
        }
    }
}
