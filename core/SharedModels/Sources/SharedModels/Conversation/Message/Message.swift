import Foundation
import UserStore

public struct Message: BaseMessage {

    public var id: Int64
    public var author: ConversationUser?
    public var creationDate: Date?
    public var content: String?
    public var tokenizedContent: String?
    public var authorRoleTransient: UserRole?

    public var title: String?
    public var visibleForStudents: Bool?
    public var reactions: [Reaction]?
    public var answers: [AnswerMessage]?
    public var tags: [String]?
    public var exercise: Exercise?
    public var lecture: Lecture?
    public var course: Course?
    public var courseWideContext: CourseWideContext?
    public var conversation: Conversation?
    public var displayPriority: DisplayPriority?
//    var plagiarismCase: PlagiarismCase?
    public var resolved: Bool?
    public var answerCount: Int?
    public var voteCount: Int?

    public func containsReactionFromMe(emojiId: String) -> Bool {
        getReactionFromMe(emojiId: emojiId) != nil
    }

    public func getReactionFromMe(emojiId: String) -> Reaction? {
        guard let userId = UserSession.shared.userId else { return nil }
        return (reactions ?? []).first(where: {
            guard let authorId = $0.user?.id else { return false }
            return authorId == userId && $0.emojiId == emojiId
        })
    }
}

extension Message: Equatable, Hashable {
    public static func == (lhs: Message, rhs: Message) -> Bool {
        lhs.id == rhs.id &&
        lhs.answers?.count ?? 0 == rhs.answers?.count ?? 0 &&
        lhs.reactions?.count ?? 0 == rhs.reactions?.count ?? 0
    }

    public func hash(into hasher: inout Hasher) {
        hasher.combine(id)
    }
}
