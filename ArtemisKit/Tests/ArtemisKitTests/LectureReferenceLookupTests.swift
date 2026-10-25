import Common
import SharedModels
import XCTest
@testable import Messages
@testable import Navigation

@MainActor
final class LectureReferenceLookupTests: XCTestCase {
    func testNetworkFailureShowsRetryAndRetryOpensActualUnit() async throws {
        let lecture = try JSONDecoder().decode(Lecture.self, from: Data(#"{"id":2,"lectureUnits":[{"id":5,"type":"text"}]}"#.utf8))
        var attempts = 0
        var opened: LecturePath?
        let lookup = LectureReferenceLookup(coursePath: CoursePath(id: 1), loader: {
            attempts += 1
            return attempts == 1 ? .failure(error: UserFacingError(title: "Offline")) : .done(response: [lecture])
        }, navigate: { opened = $0 }, openLectures: {}, isCurrent: { true })
        await lookup.openUnit(5)
        XCTAssertEqual(lookup.failure, .network)
        XCTAssertNil(opened)
        await lookup.retry()
        XCTAssertNil(lookup.failure)
        XCTAssertEqual(opened?.target?.unitId, 5)
    }

    func testMissingUnitOffersOpenLecturesRecovery() async {
        var courseOpened = false
        let lookup = LectureReferenceLookup(coursePath: CoursePath(id: 1), loader: { .done(response: []) },
            navigate: { _ in XCTFail("A missing unit must not navigate to an unrelated lecture") },
            openLectures: { courseOpened = true }, isCurrent: { true })
        await lookup.openUnit(999)
        XCTAssertEqual(lookup.failure, .missing)
        lookup.showLectures()
        XCTAssertTrue(courseOpened)
        XCTAssertNil(lookup.failure)
    }
}
