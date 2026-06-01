import Foundation
import Navigation
import SwiftUI

public extension NavigationController {
    func goToIrisSession(courseId: Int, sessionId: Int) {
        goToCourse(id: courseId)
        courseTab = .iris
        selectedPath = IrisSessionPath(sessionId: sessionId, coursePath: CoursePath(id: courseId))
        tabPath = NavigationPath()
    }
}
