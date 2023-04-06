import SharedModels
import Foundation

struct Message: BaseMessage {

    var id: Int64
    var author: User
    var creationDate: Date
    var content: String
    var tokenizedContent: String
    var authorRoleTransient: UserRole?

    var title: String
    var visibleForStudents: Bool
    var reactions = Set<Reaction>()
    var answers = Set<AnswerMessage>()
    var tags = Set<String>()
    var exercise: Exercise?
    var lecture: Lecture?
    var course: Course?
    var courseWideContext: CourseWideContext
    var conversation: Conversation?
    var displayPriority = DisplayPriority.none
//    var plagiarismCase: PlagiarismCase?
    var resolved: Bool
    var answerCount: Int
    var voteCount: Int
}
