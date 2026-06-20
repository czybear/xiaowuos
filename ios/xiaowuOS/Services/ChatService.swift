import Foundation

@MainActor
final class ChatService: ObservableObject {
    @Published private(set) var conversations: [ChatConversation] = []
    @Published private(set) var messagesByConversation: [String: [ChatMessage]] = [:]
    @Published var statusMessage = "连接 xiaowuOS 服务端"

    private let baseURL = URL(string: "http://127.0.0.1:8765")!
    private let currentUserId = "student-demo"
    private let currentUserName = "学员"

    init() {
        loadPreviewData()
    }

    func refreshConversations() {
        Task {
            do {
                let response: ChatListResponse<ChatConversation> = try await request("/api/chat/conversations")
                conversations = response.items
                statusMessage = "已连接服务端"
            } catch {
                statusMessage = "使用本地预览消息"
                if conversations.isEmpty {
                    loadPreviewData()
                }
            }
        }
    }

    func refreshMessages(for conversation: ChatConversation) {
        Task {
            do {
                let response: ChatListResponse<ChatMessage> = try await request("/api/chat/conversations/\(conversation.id)/messages")
                messagesByConversation[conversation.id] = response.items
                statusMessage = "已连接服务端"
            } catch {
                statusMessage = "使用本地预览消息"
                if messagesByConversation[conversation.id] == nil {
                    messagesByConversation[conversation.id] = previewMessages(conversationId: conversation.id)
                }
            }
        }
    }

    func sendMessage(_ text: String, in conversation: ChatConversation) {
        let trimmed = text.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        let previewMessage = ChatMessage(
            id: UUID().uuidString,
            conversationId: conversation.id,
            senderId: currentUserId,
            senderName: currentUserName,
            senderRole: "student",
            body: trimmed,
            messageType: "text",
            createdAt: ISO8601DateFormatter().string(from: Date())
        )
        messagesByConversation[conversation.id, default: []].append(previewMessage)

        Task {
            do {
                let payload = SendMessagePayload(
                    senderId: currentUserId,
                    senderName: currentUserName,
                    senderRole: "student",
                    body: trimmed
                )
                let saved: ChatMessage = try await post("/api/chat/conversations/\(conversation.id)/messages", payload: payload)
                replacePreviewMessage(previewMessage.id, with: saved, conversationId: conversation.id)
                refreshConversations()
            } catch {
                statusMessage = "消息已保存在本地预览"
            }
        }
    }

    private func replacePreviewMessage(_ previewId: String, with saved: ChatMessage, conversationId: String) {
        guard var messages = messagesByConversation[conversationId],
              let index = messages.firstIndex(where: { $0.id == previewId }) else {
            return
        }

        messages[index] = saved
        messagesByConversation[conversationId] = messages
    }

    private func request<T: Decodable>(_ path: String) async throws -> T {
        let url = baseURL.appending(path: path)
        let (data, response) = try await URLSession.shared.data(from: url)
        try validate(response)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func post<T: Decodable, P: Encodable>(_ path: String, payload: P) async throws -> T {
        let url = baseURL.appending(path: path)
        var request = URLRequest(url: url)
        request.httpMethod = "POST"
        request.setValue("application/json; charset=utf-8", forHTTPHeaderField: "Content-Type")
        request.httpBody = try JSONEncoder().encode(payload)
        let (data, response) = try await URLSession.shared.data(for: request)
        try validate(response)
        return try JSONDecoder().decode(T.self, from: data)
    }

    private func validate(_ response: URLResponse) throws {
        guard let httpResponse = response as? HTTPURLResponse,
              (200..<300).contains(httpResponse.statusCode) else {
            throw URLError(.badServerResponse)
        }
    }

    private func loadPreviewData() {
        let conversation = ChatConversation(
            id: "teacher-room",
            title: "澄木老师答疑群",
            kind: "group",
            avatarText: "澄",
            openclawChannel: "openclaw://xiaowuos/teacher-room",
            lastMessage: "欢迎来到小悟同学，这里会用于课程通知、作业交流和答疑。",
            lastMessageAt: nil,
            participants: [
                ChatParticipant(id: "teacher-chengmu", name: "澄木老师", role: "teacher"),
                ChatParticipant(id: currentUserId, name: currentUserName, role: "student")
            ]
        )
        conversations = [conversation]
        messagesByConversation[conversation.id] = previewMessages(conversationId: conversation.id)
    }

    private func previewMessages(conversationId: String) -> [ChatMessage] {
        [
            ChatMessage(
                id: "preview-welcome",
                conversationId: conversationId,
                senderId: "teacher-chengmu",
                senderName: "澄木老师",
                senderRole: "teacher",
                body: "欢迎来到小悟同学，这里会用于课程通知、作业交流和答疑。",
                messageType: "text",
                createdAt: ISO8601DateFormatter().string(from: Date())
            )
        ]
    }
}

private struct SendMessagePayload: Encodable {
    let senderId: String
    let senderName: String
    let senderRole: String
    let body: String

    enum CodingKeys: String, CodingKey {
        case senderId = "sender_id"
        case senderName = "sender_name"
        case senderRole = "sender_role"
        case body
    }
}
