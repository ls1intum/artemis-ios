import Foundation

public struct UnknownParticipation: BaseParticipation, Decodable {
    public static var type: String {
        "unknown"
    }

    public var id: Int? = nil
    public var initializationState: InitializationState? = nil
    public var initializationDate: Date? = nil
    public var individualDueDate: Date? = nil
    public var results: [Result]? = nil
    public var exercise: Exercise? = nil
    public var submissions: [Submission]? = nil
}
