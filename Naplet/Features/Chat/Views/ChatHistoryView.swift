import SwiftUI

// MARK: - Chat History View
struct ChatHistoryView: View {
    @ObservedObject private var historyManager = ChatHistoryManager.shared
    @Environment(\.dismiss) private var dismiss

    let baby: Baby
    let sleepRecords: [SleepRecord]
    let onSelectConversation: (ChatConversation) -> Void
    let onNewConversation: () -> Void

    var body: some View {
        NavigationStack {
            ZStack {
                NapletColors.background
                    .ignoresSafeArea()

                if filteredConversations.isEmpty {
                    emptyStateView
                } else {
                    conversationListView
                }
            }
            .navigationTitle("chat.history.title".localized)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("common.close".localized) {
                        dismiss()
                    }
                    .foregroundColor(NapletColors.primaryPurple)
                }

                ToolbarItem(placement: .navigationBarTrailing) {
                    Button {
                        onNewConversation()
                        dismiss()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(NapletColors.gradientPrimary)
                    }
                }
            }
        }
        .presentationDetents([.medium, .large])
        .presentationDragIndicator(.visible)
    }

    // MARK: - Filtered Conversations
    private var filteredConversations: [ChatConversation] {
        historyManager.getConversations(for: baby.id)
    }

    // MARK: - Empty State
    private var emptyStateView: some View {
        VStack(spacing: NapletSpacing.lg) {
            ZStack {
                Circle()
                    .fill(NapletColors.primaryPurple.opacity(0.1))
                    .frame(width: 80, height: 80)

                Image(systemName: "bubble.left.and.bubble.right")
                    .font(.system(size: 32))
                    .foregroundStyle(NapletColors.gradientPrimary)
            }

            VStack(spacing: NapletSpacing.sm) {
                Text("chat.history.empty.title".localized)
                    .font(NapletTypography.headline())
                    .foregroundColor(NapletColors.textPrimary)

                Text("chat.history.empty.subtitle".localized)
                    .font(NapletTypography.body())
                    .foregroundColor(NapletColors.textSecondary)
                    .multilineTextAlignment(.center)
            }

            Button {
                onNewConversation()
                dismiss()
            } label: {
                HStack(spacing: NapletSpacing.sm) {
                    Image(systemName: "plus")
                    Text("chat.history.startNew".localized)
                }
                .font(NapletTypography.body(weight: .semibold))
                .foregroundColor(.white)
                .padding(.horizontal, NapletSpacing.xl)
                .padding(.vertical, NapletSpacing.md)
                .background(NapletColors.gradientPrimary)
                .cornerRadius(12)
            }
        }
        .padding(NapletSpacing.xl)
    }

    // MARK: - Conversation List
    private var conversationListView: some View {
        List {
            ForEach(filteredConversations) { conversation in
                ConversationRow(conversation: conversation)
                    .contentShape(Rectangle())
                    .onTapGesture {
                        onSelectConversation(conversation)
                        dismiss()
                    }
                    .listRowBackground(NapletColors.backgroundSecondary)
                    .listRowSeparator(.hidden)
                    .listRowInsets(EdgeInsets(
                        top: NapletSpacing.sm,
                        leading: NapletSpacing.md,
                        bottom: NapletSpacing.sm,
                        trailing: NapletSpacing.md
                    ))
            }
            .onDelete(perform: deleteConversation)
        }
        .listStyle(.plain)
        .scrollContentBackground(.hidden)
    }

    // MARK: - Delete Conversation
    private func deleteConversation(at offsets: IndexSet) {
        for index in offsets {
            let conversation = filteredConversations[index]
            historyManager.deleteConversation(conversation)
        }
    }
}

// MARK: - Conversation Row
struct ConversationRow: View {
    let conversation: ChatConversation

    var body: some View {
        VStack(alignment: .leading, spacing: NapletSpacing.sm) {
            // Title and date
            HStack {
                Text(conversation.title)
                    .font(NapletTypography.body(weight: .semibold))
                    .foregroundColor(NapletColors.textPrimary)
                    .lineLimit(1)

                Spacer()

                Text(formatDate(conversation.updatedAt))
                    .font(NapletTypography.caption())
                    .foregroundColor(NapletColors.textMuted)
            }

            // Preview
            Text(conversation.lastMessagePreview)
                .font(NapletTypography.caption())
                .foregroundColor(NapletColors.textSecondary)
                .lineLimit(2)

            // Message count
            HStack(spacing: NapletSpacing.xs) {
                Image(systemName: "bubble.left")
                    .font(.system(size: 10))
                Text("\(conversation.userMessageCount) \("chat.history.messages".localized)")
                    .font(.system(size: 10))
            }
            .foregroundColor(NapletColors.textMuted)
        }
        .padding(NapletSpacing.md)
        .background(NapletColors.background)
        .cornerRadius(12)
    }

    private func formatDate(_ date: Date) -> String {
        let calendar = Calendar.current

        if calendar.isDateInToday(date) {
            return "common.today".localized
        } else if calendar.isDateInYesterday(date) {
            return "common.yesterday".localized
        } else {
            let formatter = DateFormatter()
            formatter.dateStyle = .short
            return formatter.string(from: date)
        }
    }
}

// MARK: - Preview
#Preview {
    ChatHistoryView(
        baby: Baby.preview,
        sleepRecords: [],
        onSelectConversation: { _ in },
        onNewConversation: {}
    )
}
