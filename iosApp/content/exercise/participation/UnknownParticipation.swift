import Foundation

struct UnknownParticipation: BaseParticipation, Decodable {
    static var type: String {
        "unknown"
    }

    var id: Int? = nil
    var initializationState: InitializationState? = nil
    var initializationDate: Date? = nil
    var individualDueDate: Date? = nil
    var results: [Result]? = nil
    var exercise: Exercise? = nil
    var submissions: [Submission]? = nil
}
