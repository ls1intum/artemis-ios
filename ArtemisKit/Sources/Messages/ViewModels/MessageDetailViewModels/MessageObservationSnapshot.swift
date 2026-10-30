import Common
import Foundation
import SharedModels

/// The values that message views observe, without imposing equality on Common's DataState.
struct MessageObservationSnapshot: Equatable {
    private enum State: Equatable {
        case loading
        case failure(UserFacingError)
        case done(Content)
    }

    private let state: State

    init(_ message: DataState<BaseMessage>) {
        switch message {
        case .loading:
            state = .loading
        case .failure(let error):
            state = .failure(error)
        case .done(let message):
            state = .done(Content(message))
        }
    }

    private struct Content: Equatable {
        let id: Int64
        let author: ConversationUser?
        let authorRole: UserRole?
        let creationDate: Date?
        let updatedDate: Date?
        let content: String?
        let tokenizedContent: String?
        let reactions: [ReactionContent]?
        let answers: [Content]?
        let displayPriority: DisplayPriority?
        let resolved: Bool?
        let resolvesPost: Bool?
        let isSaved: Bool?
        let hasForwardedMessages: Bool?

        init(_ message: BaseMessage) {
            id = message.id
            author = message.author
            authorRole = message.authorRole
            creationDate = message.creationDate
            updatedDate = message.updatedDate
            content = message.content
            tokenizedContent = message.tokenizedContent
            reactions = message.reactions?.map(ReactionContent.init)
            let post = message as? Message
            let answer = message as? AnswerMessage
            answers = post?.answers?.map(Content.init)
            displayPriority = post?.displayPriority
            resolved = post?.resolved
            resolvesPost = answer?.resolvesPost
            isSaved = post?.isSaved ?? answer?.isSaved
            hasForwardedMessages = post?.hasForwardedMessages
        }
    }

    // SharedModels.Reaction compares only IDs; changes to an existing reaction still update the UI.
    private struct ReactionContent: Equatable {
        let id: Int64
        let emojiId: String
        let user: ConversationUser?
        let creationDate: Date?

        init(_ reaction: Reaction) {
            id = reaction.id
            emojiId = reaction.emojiId
            user = reaction.user
            creationDate = reaction.creationDate
        }
    }
}
