import Foundation
import Navigation
import SharedModels

public struct IrisSessionPath: Hashable {
    public let sessionId: Int
    public let session: IrisSessionDTO?
    public let coursePath: CoursePath

    public init(sessionId: Int, coursePath: CoursePath) {
        self.sessionId = sessionId
        self.session = nil
        self.coursePath = coursePath
    }

    public init(session: IrisSessionDTO, coursePath: CoursePath) {
        self.sessionId = session.id
        self.session = session
        self.coursePath = coursePath
    }
}
