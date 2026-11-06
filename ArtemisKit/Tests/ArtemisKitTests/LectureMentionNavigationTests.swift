import SwiftUI
import XCTest
@testable import Messages
@testable import Navigation

@MainActor
final class LectureMentionNavigationTests: XCTestCase {
    func testReferenceCallbackPreservesOriginatingTabAndConversationForBack() throws {
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
            let originalTabPath = navigation.tabPath
            let originalSelection = navigation.selectedPath as? LecturePath
            let callback = MessageURLAction.lectureNavigation(using: navigation)
            callback(LecturePath(id: 1, coursePath: course, target: target))
            let selected = try XCTUnwrap(navigation.selectedPath as? LecturePath)
            XCTAssertEqual(navigation.lectureMediaPath.last?.target, target)
            XCTAssertEqual(selected, originalSelection)
            XCTAssertEqual(selected.id, 1)
            XCTAssertEqual(navigation.courseTab, startingTab)
            XCTAssertEqual(navigation.selectedCourse?.id, 182)
            XCTAssertEqual(navigation.tabPath, originalTabPath)
            XCTAssertEqual(navigation.outerPath, originalOuterPath, "The visible course owns this navigation")
        }
    }

    func testRepeatedSameReferenceCreatesANewPageAfterBack() throws {
        let navigation = NavigationController()
        let target = LectureMediaTarget(unitId: 8, slideId: 19, originalSlideNumber: 8)
        navigation.goToLecture(courseId: 182, lectureId: 1, target: target)
        let first = try XCTUnwrap(navigation.lectureMediaPath.last)
        navigation.lectureMediaPath.removeLast() // Native Back.
        navigation.goToLecture(courseId: 182, lectureId: 1, target: target)
        let second = try XCTUnwrap(navigation.lectureMediaPath.last)
        XCTAssertEqual(first.target, second.target)
        XCTAssertNotEqual(first, second, "A repeated open gets fresh target consumption state")
        XCTAssertEqual(navigation.lectureMediaPath.count, 1)
    }

    func testLeavingTheCourseClearsMediaPages() {
        let navigation = NavigationController()
        navigation.openLectureMedia(courseId: 182, lectureId: 1, target: .init(unitId: 8))
        navigation.goToCourse(id: 2)
        XCTAssertTrue(navigation.lectureMediaPath.isEmpty)
        XCTAssertEqual(navigation.selectedCourse?.id, 2)
    }

    func testOrdinaryLectureNavigationStillSelectsOverview() {
        let navigation = NavigationController()
        navigation.openLectureMedia(courseId: 182, lectureId: 1, target: .init(unitId: 8))
        navigation.goToLecture(courseId: 182, lectureId: 2)
        XCTAssertTrue(navigation.lectureMediaPath.isEmpty)
        XCTAssertEqual((navigation.selectedPath as? LecturePath)?.id, 2)
        XCTAssertEqual(navigation.courseTab, .lecture)
    }
}
