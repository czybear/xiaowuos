import SwiftUI

struct ChatCenterView: View {
    @EnvironmentObject private var chatService: ChatService

    var body: some View {
        List {
            Section {
                HStack(spacing: 12) {
                    Image(systemName: "message.badge.filled.fill")
                        .font(.title3)
                        .foregroundStyle(.white)
                        .frame(width: 42, height: 42)
                        .background(.orange, in: RoundedRectangle(cornerRadius: 8))

                    VStack(alignment: .leading, spacing: 4) {
                        Text("小悟消息")
                            .font(.headline)
                        Text(chatService.statusMessage)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
                .padding(.vertical, 4)
            }

            Section("会话") {
                ForEach(chatService.conversations) { conversation in
                    NavigationLink {
                        ChatThreadView(conversation: conversation)
                    } label: {
                        ConversationRow(conversation: conversation)
                    }
                }
            }
        }
        .navigationTitle("消息")
        .onAppear {
            chatService.refreshConversations()
        }
    }
}

private struct ConversationRow: View {
    let conversation: ChatConversation

    var body: some View {
        HStack(spacing: 12) {
            Text(conversation.avatarText.isEmpty ? "讯" : conversation.avatarText)
                .font(.headline.weight(.semibold))
                .foregroundStyle(.white)
                .frame(width: 44, height: 44)
                .background(.orange, in: RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                HStack {
                    Text(conversation.title)
                        .font(.subheadline.weight(.semibold))
                    Spacer()
                    Text(conversation.kind == "group" ? "群聊" : "私聊")
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }

                Text(conversation.lastMessage ?? "暂无消息")
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(.vertical, 6)
    }
}

private struct ChatThreadView: View {
    @EnvironmentObject private var chatService: ChatService
    let conversation: ChatConversation
    @State private var draft = ""

    var body: some View {
        VStack(spacing: 0) {
            ScrollView {
                LazyVStack(spacing: 12) {
                    ForEach(chatService.messagesByConversation[conversation.id] ?? []) { message in
                        MessageBubble(message: message, isMine: message.senderRole == "student")
                    }
                }
                .padding(16)
            }
            .background(Color(.systemGroupedBackground))

            HStack(spacing: 10) {
                TextField("发消息", text: $draft, axis: .vertical)
                    .lineLimit(1...4)
                    .padding(12)
                    .background(Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))

                Button {
                    chatService.sendMessage(draft, in: conversation)
                    draft = ""
                } label: {
                    Image(systemName: "paperplane.fill")
                        .frame(width: 34, height: 34)
                }
                .buttonStyle(.borderedProminent)
                .disabled(draft.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding(12)
            .background(.regularMaterial)
        }
        .navigationTitle(conversation.title)
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            chatService.refreshMessages(for: conversation)
        }
    }
}

private struct MessageBubble: View {
    let message: ChatMessage
    let isMine: Bool

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if isMine { Spacer(minLength: 44) }

            if !isMine {
                avatar
            }

            VStack(alignment: isMine ? .trailing : .leading, spacing: 4) {
                Text(message.senderName)
                    .font(.caption2)
                    .foregroundStyle(.secondary)

                Text(message.body)
                    .font(.subheadline)
                    .foregroundStyle(isMine ? .white : .primary)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 10)
                    .background(isMine ? Color.orange : Color(.secondarySystemGroupedBackground), in: RoundedRectangle(cornerRadius: 8))
            }

            if isMine {
                avatar
            }

            if !isMine { Spacer(minLength: 44) }
        }
    }

    private var avatar: some View {
        Text(String(message.senderName.prefix(1)))
            .font(.caption.weight(.semibold))
            .foregroundStyle(.white)
            .frame(width: 30, height: 30)
            .background(isMine ? Color.gray : Color.orange, in: RoundedRectangle(cornerRadius: 8))
    }
}

#Preview {
    NavigationStack {
        ChatCenterView()
            .environmentObject(ChatService())
    }
}
