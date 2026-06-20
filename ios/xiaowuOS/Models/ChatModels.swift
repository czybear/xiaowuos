import Foundation

struct ChatConversation: Codable, Identifiable, Equatable {
    let id: String
    var title: String
    var kind: String
    var avatarText: String
    var openclawChannel: String
    var lastMessage: String?
    var lastMessageAt: String?
    var participants: [ChatParticipant]

    enum CodingKeys: String, CodingKey {
        case id
        case title
        case kind
        case avatarText = "avatar_text"
        case openclawChannel = "openclaw_channel"
        case lastMessage = "last_message"
        case lastMessageAt = "last_message_at"
        case participants
    }
}

struct ChatParticipant: Codable, Identifiable, Equatable {
    let id: String
    var name: String
    var role: String
}

struct ChatMessage: Codable, Identifiable, Equatable {
    let id: String
    var conversationId: String
    var senderId: String
    var senderName: String
    var senderRole: String
    var body: String
    var messageType: String
    var createdAt: String

    enum CodingKeys: String, CodingKey {
        case id
        case conversationId = "conversation_id"
        case senderId = "sender_id"
        case senderName = "sender_name"
        case senderRole = "sender_role"
        case body
        case messageType = "message_type"
        case createdAt = "created_at"
    }
}

struct ChatListResponse<T: Decodable>: Decodable {
    let items: [T]
    let count: Int
}
