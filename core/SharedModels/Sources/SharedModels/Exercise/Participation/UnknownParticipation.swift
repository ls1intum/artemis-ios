import Foundation

public struct UnknownParticipation: BaseParticipation {
    public static var type: String {
        "unknown"
    }

    public var id: Int
    public var initializationState: InitializationState?
    public var initializationDate: Date?
    public var individualDueDate: Date?
    public var results: [Result]?
    public var exercise: Exercise?
    public var submissions: [Submission]?
}
