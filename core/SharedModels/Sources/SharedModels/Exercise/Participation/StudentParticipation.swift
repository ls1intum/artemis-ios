import Foundation

public protocol StudentParticipation: BaseParticipation {
    //    var student: User? { get }
    var team: Team? { get }
    var participantIdentifier: String? { get }
    var testRun: Bool? { get }
}

public struct StudentParticipationImpl: StudentParticipation, Codable {

    public static var type: String {
        "student"
    }

    public var student: User?
    public var team: Team?
    public var participantIdentifier: String?
    public var testRun: Bool?
    public var id: Int
    public var initializationState: InitializationState?
    public var initializationDate: Date?
    public var individualDueDate: Date?
    public var results: [Result]?
    public var exercise: Exercise?
    public var submissions: [Submission]?
}
