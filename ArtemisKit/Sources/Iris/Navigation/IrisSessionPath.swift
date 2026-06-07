import Foundation
import Navigation
import SharedModels

struct IrisSessionPath: Hashable {
    let sessionId: Int
    let session: IrisSessionDTO?
    let coursePath: CoursePath

    /// Convenience for the enclosing course's id.
    var courseId: Int {
        coursePath.id
    }

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

    /// Identity is keyed on `sessionId` only. The embedded `session` DTO is a
    /// mutable snapshot (title and context update live in the list)
    static func == (lhs: IrisSessionPath, rhs: IrisSessionPath) -> Bool {
        lhs.sessionId == rhs.sessionId
    }

    func hash(into hasher: inout Hasher) {
        hasher.combine(sessionId)
    }
}
