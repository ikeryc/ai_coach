import Foundation
import SwiftData

@Model
final class AIConversation {

    @Attribute(.unique) var id: UUID
    var title: String
    var createdAt: Date
    var updatedAt: Date

    var userProfile: UserProfile?

    @Relationship(deleteRule: .cascade)
    var messages: [AIMessage] = []

    init(
        id: UUID = UUID(),
        title: String = "Nueva conversación",
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.title = title
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }

    var lastMessage: AIMessage? {
        messages.sorted { $0.createdAt < $1.createdAt }.last
    }

    var sortedMessages: [AIMessage] {
        messages.sorted { $0.createdAt < $1.createdAt }
    }
}

// MARK: - AIMessage

@Model
final class AIMessage {

    @Attribute(.unique) var id: UUID
    var role: MessageRole
    var content: String
    var contextSnapshot: Data?          // JSON snapshot de datos inyectados
    var tokensUsed: Int?
    var createdAt: Date

    var conversation: AIConversation?

    init(
        id: UUID = UUID(),
        role: MessageRole,
        content: String,
        contextSnapshot: Data? = nil,
        tokensUsed: Int? = nil,
        createdAt: Date = .now
    ) {
        self.id = id
        self.role = role
        self.content = content
        self.contextSnapshot = contextSnapshot
        self.tokensUsed = tokensUsed
        self.createdAt = createdAt
    }

    var isFromUser: Bool {
        role == .user
    }
}

// MARK: - Enums

enum MessageRole: String, Codable {
    case user = "user"
    case assistant = "assistant"
    case system = "system"
}
