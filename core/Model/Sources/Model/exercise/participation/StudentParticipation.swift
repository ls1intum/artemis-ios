import Foundation

public protocol StudentParticipation: BaseParticipation, Decodable {
//    var student: User? { get }
    var team: Team? { get }
    var participantIdentifier: String? { get }
    var testRun: Bool? { get }
}

public struct StudentParticipationImpl: StudentParticipation, Decodable {

    public static var type: String {
        "student"
    }

    public var student: User? = nil
    public var team: Team? = nil
    public var participantIdentifier: String? = nil
    public var testRun: Bool? = nil
    public var id: Int? = nil
    public var initializationState: InitializationState? = nil
    public var initializationDate: Date? = nil
    public var individualDueDate: Date? = nil
    public var results: [Result]? = nil
    public var exercise: Exercise? = nil
    public var submissions: [Submission]? = nil
}