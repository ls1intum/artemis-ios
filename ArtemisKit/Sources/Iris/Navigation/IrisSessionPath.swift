import Foundation
import Navigation

struct IrisSessionPath: Hashable {
    let sessionId: Int
    let coursePath: CoursePath

    /// Convenience for the enclosing course's id.
    var courseId: Int {
        coursePath.id
    }

    init(sessionId: Int, coursePath: CoursePath) {
        self.sessionId = sessionId
        self.coursePath = coursePath
    }
}
