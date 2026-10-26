import SwiftUI
import XCTest
@testable import Messages
@testable import Navigation

@MainActor
final class LectureMentionNavigationTests: XCTestCase {
    func testReferenceCallbackSelectsVisibleCourseLectureAndRemovesConversationStack() throws {
        let course = CoursePath(id: 182)
        let target = LectureMediaTarget(unitId: 8, slideId: 19, originalSlideNumber: 8, visibleSlideNumbers: [1, 3, 8])
        for startingTab in [TabIdentifier.lecture, .communication] {
            let navigation = NavigationController()
            navigation.selectedCourse = course
            navigation.courseTab = startingTab
            navigation.selectedPath = LecturePath(id: 1, coursePath: course)
            navigation.tabPath.append(ConversationPath(id: 892, coursePath: course))
            navigation.outerPath.append("existing root destination")
            let originalOuterPath = navigation.outerPath
            let callback = MessageURLAction.lectureNavigation(using: navigation)
            callback(LecturePath(id: 1, coursePath: course, target: target))
            let selected = try XCTUnwrap(navigation.selectedPath as? LecturePath)
            XCTAssertEqual(selected.target, target)
            XCTAssertEqual(selected.id, 1)
            XCTAssertEqual(navigation.courseTab, .lecture)
            XCTAssertEqual(navigation.selectedCourse?.id, 182)
            XCTAssertTrue(navigation.tabPath.isEmpty)
            XCTAssertEqual(navigation.outerPath, originalOuterPath, "The visible course owns this navigation")
        }
    }

    func testRepeatedSameReferenceCreatesANewPresentationEvent() throws {
        let navigation = NavigationController()
        let target = LectureMediaTarget(unitId: 8, slideId: 19, originalSlideNumber: 8)
        navigation.goToLecture(courseId: 182, lectureId: 1, target: target)
        let first = try XCTUnwrap(navigation.selectedPath as? LecturePath)
        navigation.tabPath.append(ConversationPath(id: 892, coursePath: CoursePath(id: 182)))
        navigation.goToLecture(courseId: 182, lectureId: 1, target: target)
        let second = try XCTUnwrap(navigation.selectedPath as? LecturePath)
        XCTAssertEqual(first.target, second.target)
        XCTAssertNotEqual(first, second, "An intentional repeated open must not reuse consumed target state")
        XCTAssertNotEqual(first.presentationIdentity, second.presentationIdentity)
        XCTAssertEqual(LecturePath(id: 1, coursePath: CoursePath(id: 182)), LecturePath(id: 1, coursePath: CoursePath(id: 182)))
        XCTAssertTrue(navigation.tabPath.isEmpty)
    }
}
