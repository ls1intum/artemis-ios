import Foundation

protocol StudentParticipation: BaseParticipation, Decodable {
//    var student: User? { get }
    var team: Team? { get }
    var participantIdentifier: String? { get }
    var testRun: Bool? { get }
}

struct StudentParticipationImpl: StudentParticipation, Decodable {

    public static var type: String {
        "student"
    }

    var student: User? = nil
    var team: Team? = nil
    var participantIdentifier: String? = nil
    var testRun: Bool? = nil
    var id: Int? = nil
    var initializationState: InitializationState? = nil
    var initializationDate: Date? = nil
    var individualDueDate: Date? = nil
    var results: [Result]? = nil
    var exercise: Exercise? = nil
    var submissions: [Submission]? = nil
}