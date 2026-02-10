import SwiftUI

// MARK: - Chat View
struct ChatView: View {
    @StateObject private var viewModel = ChatViewModel()
    @ObservedObject private var subscriptionManager = SubscriptionManager.shared
    @FocusState private var isInputFocused: Bool
    @Environment(\.dismiss) private var dismiss
    @State private var showPaywall = false
    @State private var showHistory = false

    let baby: Baby
    let sleepRecords: [SleepRecord]
    
    /// Input is disabled only if limit reached AND user is NOT premium
    private var isInputDisabled: Bool {
        viewModel.hasReachedLimit && !subscriptionManager.hasUnlimitedChat
    }

    var body: some View {
        ZStack {
            NapletColors.background
                .ignoresSafeArea()

            VStack(spacing: 0) {
                // Drag Indicator
                Capsule()
                    .fill(NapletColors.textMuted.opacity(0.3))
                    .frame(width: 36, height: 5)
                    .padding(.top, NapletSpacing.sm)
                    .padding(.bottom, NapletSpacing.xs)

                // Header
                headerView

                // Messages
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: NapletSpacing.md) {
                            // Remaining chats indicator (only for non-premium users)
                            if !subscriptionManager.hasUnlimitedChat && viewModel.remainingFreeChats <= 3 {
                                remainingChatsView
                            }

                            // Upgrade banner when limit reached
                            if viewModel.hasReachedLimit && !subscriptionManager.hasUnlimitedChat {
                                upgradeBannerView
                            }

                            // Suggested questions (only if no user messages yet)
                            if viewModel.messages.count <= 1 {
                                suggestedQuestionsView
                            }

                            ForEach(viewModel.messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }

                            if viewModel.isLoading {
                                TypingIndicator()
                                    .id("typing")
                            }
                        }
                        .padding(.horizontal, NapletSpacing.md)
                        .padding(.vertical, NapletSpacing.sm)
                    }
                    .onChange(of: viewModel.messages.count) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                    .onChange(of: viewModel.isLoading) { _, _ in
                        scrollToBottom(proxy: proxy)
                    }
                }

                // Input
                inputView
            }
        }
        .onAppear {
            viewModel.setup(baby: baby, sleepRecords: sleepRecords)
        }
        .alert(L10n.Common.error.localized, isPresented: .init(
            get: { viewModel.errorMessage != nil },
            set: { if !$0 { viewModel.errorMessage = nil } }
        )) {
            Button(L10n.Common.ok.localized) { viewModel.errorMessage = nil }
        } message: {
            Text(viewModel.errorMessage ?? "")
        }
        .sheet(isPresented: $showPaywall) {
            PaywallView()
        }
        .sheet(isPresented: $showHistory) {
            ChatHistoryView(
                baby: baby,
                sleepRecords: sleepRecords,
                onSelectConversation: { conversation in
                    viewModel.loadConversation(conversation)
                },
                onNewConversation: {
                    viewModel.startNewConversation()
                }
            )
        }
        .presentationDetents([.large])
        .presentationDragIndicator(.hidden)
        .presentationCornerRadius(24)
    }

    private func scrollToBottom(proxy: ScrollViewProxy) {
        withAnimation(.easeOut(duration: 0.3)) {
            if viewModel.isLoading {
                proxy.scrollTo("typing", anchor: .bottom)
            } else if let lastMessage = viewModel.messages.last {
                proxy.scrollTo(lastMessage.id, anchor: .bottom)
            }
        }
    }

    // MARK: - Header
    private var headerView: some View {
        HStack {
            // AI Avatar
            ZStack {
                Circle()
                    .fill(NapletColors.gradientPrimary)
                    .frame(width: 40, height: 40)

                Image(systemName: "sparkles")
                    .font(.system(size: 18))
                    .foregroundColor(.white)
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(L10n.AIChat.title.localized)
                    .font(.system(size: NapletTypography.headline, weight: .bold))
                    .foregroundColor(NapletColors.textPrimary)

                Text(L10n.AIChat.subtitle.localized)
                    .font(.system(size: NapletTypography.caption))
                    .foregroundColor(NapletColors.textMuted)
            }

            Spacer()

            // History button
            Button(action: { showHistory = true }) {
                Image(systemName: "clock.arrow.circlepath")
                    .font(.system(size: 18))
                    .foregroundColor(NapletColors.textSecondary)
            }

            // New conversation button
            Button(action: { viewModel.startNewConversation() }) {
                Image(systemName: "plus.circle")
                    .font(.system(size: 18))
                    .foregroundColor(NapletColors.primaryPurple)
            }
        }
        .padding(.horizontal, NapletSpacing.lg)
        .padding(.vertical, NapletSpacing.md)
        .background(NapletColors.backgroundSecondary)
    }

    // MARK: - Remaining Chats
    private var remainingChatsView: some View {
        HStack(spacing: NapletSpacing.sm) {
            Image(systemName: "info.circle.fill")
                .font(.system(size: 14))
                .foregroundColor(NapletColors.warning)

            Text(L10n.AIChat.remainingMessages.localized(with: viewModel.remainingFreeChats))
                .font(.system(size: NapletTypography.caption))
                .foregroundColor(NapletColors.textSecondary)
        }
        .padding(.horizontal, NapletSpacing.md)
        .padding(.vertical, NapletSpacing.sm)
        .background(NapletColors.warning.opacity(0.1))
        .cornerRadius(8)
    }

    // MARK: - Upgrade Banner
    private var upgradeBannerView: some View {
        VStack(spacing: NapletSpacing.md) {
            HStack(spacing: NapletSpacing.sm) {
                Image(systemName: "crown.fill")
                    .font(.system(size: 24))
                    .foregroundColor(NapletColors.warning)

                VStack(alignment: .leading, spacing: 2) {
                    Text("chat.limitReached.title".localized)
                        .font(NapletTypography.body(weight: .semibold))
                        .foregroundColor(NapletColors.textPrimary)

                    Text("chat.limitReached.subtitle".localized)
                        .font(NapletTypography.caption())
                        .foregroundColor(NapletColors.textSecondary)
                }

                Spacer()
            }

            Button {
                showPaywall = true
            } label: {
                Text("chat.limitReached.upgrade".localized)
                    .font(NapletTypography.body(weight: .semibold))
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, NapletSpacing.sm)
                    .background(NapletColors.gradientPrimary)
                    .cornerRadius(8)
            }
        }
        .padding(NapletSpacing.md)
        .background(NapletColors.backgroundSecondary)
        .cornerRadius(12)
    }

    // MARK: - Suggested Questions
    private var suggestedQuestionsView: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            Text(L10n.AIChat.suggestedQuestions.localized)
                .font(.system(size: NapletTypography.caption, weight: .medium))
                .foregroundColor(NapletColors.textMuted)
                .padding(.horizontal, NapletSpacing.xs)

            FlowLayout(spacing: NapletSpacing.sm) {
                ForEach(viewModel.suggestedQuestions, id: \.self) { question in
                    Button(action: {
                        viewModel.inputText = question
                        Task { await viewModel.sendMessage() }
                    }) {
                        Text(question)
                            .font(.system(size: NapletTypography.caption))
                            .foregroundColor(NapletColors.primaryPurple)
                            .padding(.horizontal, NapletSpacing.sm)
                            .padding(.vertical, NapletSpacing.xs)
                            .background(NapletColors.primaryPurple.opacity(0.1))
                            .cornerRadius(12)
                    }
                }
            }
        }
        .padding(.vertical, NapletSpacing.sm)
    }

    // MARK: - Input
    private var inputView: some View {
        VStack(spacing: 0) {
            Divider()
                .background(NapletColors.backgroundTertiary)

            HStack(spacing: NapletSpacing.sm) {
                TextField(L10n.AIChat.placeholder.localized, text: $viewModel.inputText, axis: .vertical)
                    .textFieldStyle(.plain)
                    .padding(.horizontal, NapletSpacing.md)
                    .padding(.vertical, NapletSpacing.sm)
                    .background(NapletColors.backgroundSecondary)
                    .cornerRadius(20)
                    .foregroundColor(NapletColors.textPrimary)
                    .focused($isInputFocused)
                    .lineLimit(1...5)
                    .disabled(isInputDisabled)

                Button(action: {
                    Task { await viewModel.sendMessage() }
                }) {
                    Image(systemName: "arrow.up.circle.fill")
                        .font(.system(size: 36))
                        .foregroundStyle(
                            viewModel.inputText.isEmpty || isInputDisabled ?
                            AnyShapeStyle(NapletColors.textMuted) :
                            AnyShapeStyle(NapletColors.gradientPrimary)
                        )
                }
                .disabled(viewModel.inputText.isEmpty || viewModel.isLoading || isInputDisabled)
            }
            .padding(.horizontal, NapletSpacing.md)
            .padding(.vertical, NapletSpacing.sm)
            .background(NapletColors.background)
        }
    }
}

// MARK: - Chat Bubble
struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack {
            if message.isUser { Spacer(minLength: 60) }

            VStack(alignment: message.isUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .font(.system(size: NapletTypography.body))
                    .foregroundColor(message.isUser ? .white : NapletColors.textPrimary)
                    .padding(.horizontal, NapletSpacing.md)
                    .padding(.vertical, NapletSpacing.sm)
                    .background(
                        message.isUser ?
                        AnyShapeStyle(NapletColors.gradientPrimary) :
                        AnyShapeStyle(NapletColors.backgroundSecondary)
                    )
                    .cornerRadius(16)

                Text(message.timestamp, style: .time)
                    .font(.system(size: 10))
                    .foregroundColor(NapletColors.textMuted)
            }

            if !message.isUser { Spacer(minLength: 60) }
        }
    }
}

// MARK: - Typing Indicator
struct TypingIndicator: View {
    @State private var animating = false

    var body: some View {
        HStack {
            HStack(spacing: 4) {
                ForEach(0..<3, id: \.self) { index in
                    Circle()
                        .fill(NapletColors.textMuted)
                        .frame(width: 8, height: 8)
                        .scaleEffect(animating ? 1.0 : 0.5)
                        .animation(
                            Animation.easeInOut(duration: 0.6)
                                .repeatForever()
                                .delay(Double(index) * 0.2),
                            value: animating
                        )
                }
            }
            .padding(.horizontal, NapletSpacing.md)
            .padding(.vertical, NapletSpacing.sm)
            .background(NapletColors.backgroundSecondary)
            .cornerRadius(16)

            Spacer()
        }
        .onAppear { animating = true }
    }
}

// MARK: - Flow Layout (for suggested questions)
struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)
        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

// MARK: - Preview
#Preview {
    ChatView(
        baby: Baby.preview,
        sleepRecords: []
    )
}
