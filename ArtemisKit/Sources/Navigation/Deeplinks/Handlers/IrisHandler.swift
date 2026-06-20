//
//  IrisHandler.swift
//  ArtemisKit
//

import Foundation

/// Handles deep links of the form `courses/{courseId}/iris?sessionId={sessionId}`, e.g. from an
/// Iris response push notification, by opening the referenced chat session.
struct IrisHandler: Deeplink {

    let courseId: Int
    let sessionId: Int

    static func build(from url: URL) -> IrisHandler? {
        guard let indexOfCourseId = url.pathComponents.firstIndex(where: { $0 == "courses" }),
              url.pathComponents.count > indexOfCourseId + 1,
              let courseId = Int(url.pathComponents[indexOfCourseId + 1]),
              url.pathComponents.contains("iris"),
              let components = URLComponents(url: url, resolvingAgainstBaseURL: false),
              let sessionIdValue = components.queryItems?.first(where: { $0.name == "sessionId" })?.value,
              let sessionId = Int(sessionIdValue) else { return nil }

        return IrisHandler(courseId: courseId, sessionId: sessionId)
    }

    func handle(with navigationController: NavigationController) {
        Task(priority: .userInitiated) {
            await navigationController.goToIrisSession(courseId: courseId, sessionId: sessionId)
        }
    }
}
