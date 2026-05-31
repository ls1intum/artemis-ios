import Foundation
import Navigation
import SharedModels

struct IrisSessionPath: Hashable {
    let sessionId: Int
    let session: IrisSessionDTO?
    let coursePath: CoursePath

    init(sessionId: Int, coursePath: CoursePath) {
        self.sessionId = sessionId
        self.session = nil
        self.coursePath = coursePath
    }

    init(session: IrisSessionDTO, coursePath: CoursePath) {
        self.sessionId = session.id
        self.session = session
        self.coursePath = coursePath
    }
}
