import SharedModels
import Foundation

struct Message: BaseMessage {

    var id: Int64
    var author: ConversationUser?
    var creationDate: Date?
    var content: String?
    var tokenizedContent: String?
    var authorRoleTransient: UserRole?

    var title: String?
    var visibleForStudents: Bool?
    var reactions: [Reaction]?
    var answers: [AnswerMessage]?
    var tags: [String]?
    var exercise: Exercise?
    var lecture: Lecture?
    var course: Course?
    var courseWideContext: CourseWideContext?
    var conversation: Conversation?
    var displayPriority: DisplayPriority?
//    var plagiarismCase: PlagiarismCase?
    var resolved: Bool?
    var answerCount: Int?
    var voteCount: Int?
}
