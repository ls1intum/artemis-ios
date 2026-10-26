import Common
import SharedModels
import SwiftUI
import UIKit
import XCTest
@testable import CourseView
@testable import Navigation

@MainActor
final class LectureTargetRecoveryTests: XCTestCase {
    func testRetryPresentsPendingTargetAndDismissalDoesNotReopenIt() async throws {
        let service = RecoveryLectureService()
        let model = LectureDetailViewModel(course: CourseForOverviewDTO(course: Course(id: 1, courseInformationSharingConfiguration: .communicationAndMessaging)), lectureId: 2,
                                           lectureService: service, isCurrent: { true })
        model.configureTarget(.init(unitId: 5, page: 3))
        await model.loadLecture()
        XCTAssertNil(model.targetPresentation)
        await model.loadLecture()
        XCTAssertEqual(model.targetPresentation?.unit.id, 5)
        XCTAssertEqual(model.targetPresentation?.target?.page, 3)
        model.targetPresentation = nil
        await model.loadLecture()
        XCTAssertNil(model.targetPresentation)
    }

    func testSlideRefreshReadsACompleteNewSnapshotAndRejectsHiddenIdentity() async throws {
        let service = RecoveryLectureService()
        let first = try JSONDecoder().decode(LectureMediaDetails.self, from: Data(#"{"id":2,"lectureUnits":[{"type":"attachment","id":5,"attachment":{"id":10,"studentVersion":"new-student.pdf"},"slides":[{"id":41,"slideNumber":1},{"id":99,"slideNumber":2},{"id":42,"slideNumber":3},{"id":43,"slideNumber":8}]}]}"#.utf8))
        let hidden = try JSONDecoder().decode(LectureMediaDetails.self, from: Data(#"{"id":2,"lectureUnits":[{"type":"attachment","id":5,"attachment":{"id":10,"studentVersion":"later-student.pdf"},"slides":[{"id":41,"slideNumber":1}]}]}"#.utf8))
        service.slideSnapshots = [first, hidden]
        let model = LectureDetailViewModel(course: CourseForOverviewDTO(course: Course(id: 1, courseInformationSharingConfiguration: .communicationAndMessaging)), lectureId: 2,
                                           lectureService: service, isCurrent: { true })
        let target = LectureMediaTarget(unitId: 5, slideId: 43, originalSlideNumber: 8, visibleSlideNumbers: [1, 3, 8])
        let fresh = await model.refreshSlideAccess(for: target)
        XCTAssertEqual(fresh.value?.visibleSlideNumbers, [1, 2, 3, 8])
        XCTAssertEqual(fresh.value?.studentVersion, "new-student.pdf")
        let removed = await model.refreshSlideAccess(for: target)
        if case .failure = removed {} else { XCTFail("A hidden modern slide cannot fall back to a stale index") }
        XCTAssertEqual(service.slideLoads, 2)
    }

    func testRepeatedReferenceRecreatesConsumedHostedDetail() async throws {
        let service = RecoveryLectureService()
        service.failsFirstLoad = false
        let navigation = NavigationController()
        navigation.selectedCourse = CoursePath(id: 1)
        let target = LectureMediaTarget(unitId: 5, page: 3)
        let path = LecturePath(id: 2, coursePath: CoursePath(id: 1), target: target)
        let navigate: (LecturePath) -> Void = { navigation.goToLecture(courseId: $0.coursePath.id, lectureId: $0.id, target: $0.target) }
        navigate(path)
        var models: [LectureDetailViewModel] = []
        let harness = RepeatedLectureDetailHarness(navigation: navigation) { path in
            let model = LectureDetailViewModel(course: CourseForOverviewDTO(course: Course(id: 1, courseInformationSharingConfiguration: .communicationAndMessaging)),
                                               lectureId: path.id, lectureService: service, isCurrent: { true })
            models.append(model)
            return model
        }
        let host = UIHostingController(rootView: harness)
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 800, height: 1000))
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { host.dismiss(animated: false); window.isHidden = true; window.rootViewController = nil }
        for _ in 0..<100 where host.presentedViewController == nil { try await Task.sleep(for: .milliseconds(10)) }
        let first = try XCTUnwrap(models.first { $0.targetPresentation != nil })
        XCTAssertNotNil(host.presentedViewController)
        first.targetPresentation = nil
        // Test the actual hosted StateObject consumption lifecycle. UIKit may
        // retain a presentation carrier in this unscened test window; shipping
        // UI automation verifies the visible Close and repeated-link flow.
        await Task.yield()
        navigation.tabPath.append(ConversationPath(id: 9, coursePath: CoursePath(id: 1)))
        navigate(path) // The same intentional reference, after its first sheet was closed.
        for _ in 0..<100 where !models.contains(where: { $0 !== first && $0.targetPresentation != nil }) {
            try await Task.sleep(for: .milliseconds(10))
        }
        let reopened = try XCTUnwrap(models.first { $0 !== first && $0.targetPresentation != nil })
        XCTAssertEqual(reopened.targetPresentation?.target, target)
        XCTAssertNil(first.targetPresentation, "The consumed model stays consumed")
        XCTAssertTrue(navigation.tabPath.isEmpty)
    }

    func testRetryActuallyPresentsTheNativeSheetWithRequestedPage() async throws {
        let service = RecoveryLectureService()
        let model = LectureDetailViewModel(course: CourseForOverviewDTO(course: Course(id: 1, courseInformationSharingConfiguration: .communicationAndMessaging)), lectureId: 2,
                                           lectureService: service, isCurrent: { true })
        let host = UIHostingController(rootView: LectureDetailView(viewModel: model, target: .init(unitId: 5, page: 3)))
        let window = UIWindow(frame: CGRect(x: 0, y: 0, width: 800, height: 1000))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { host.dismiss(animated: false); window.isHidden = true; window.rootViewController = nil }
        for _ in 0..<50 where service.loads == 0 { try await Task.sleep(for: .milliseconds(10)) }
        await model.loadLecture() // The same operation invoked by the DataStateView Retry action.
        for _ in 0..<100 where host.presentedViewController == nil { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertNotNil(host.presentedViewController)
        XCTAssertEqual(model.targetPresentation?.target?.page, 3)
        model.targetPresentation = nil
        host.dismiss(animated: false)

    }
}

@MainActor
private final class RecoveryLectureService: LectureService {
    var failsFirstLoad = true
    var loads = 0
    var slideLoads = 0
    var slideSnapshots: [LectureMediaDetails] = []
    func getLectureDetails(lectureId: Int) async -> DataState<LectureMediaDetails> {
        loads += 1
        if failsFirstLoad, loads == 1 { return .failure(error: UserFacingError(title: "Offline")) }
        let data = Data(#"{"id":2,"lectureUnits":[{"type":"text","id":5,"name":"Requested unit","content":"Requested unit content","visibleToStudents":true,"completed":true}]}"#.utf8)
        do { return .done(response: try JSONDecoder().decode(LectureMediaDetails.self, from: data)) }
        catch {
            XCTFail("Invalid lecture recovery fixture: \(error)")
            return .failure(error: UserFacingError(title: "Invalid test fixture"))
        }
    }
    func getLecturesWithSlides(courseId: Int) async -> DataState<[LectureMediaDetails]> {
        defer { slideLoads += 1 }
        guard slideLoads < slideSnapshots.count else { return .done(response: []) }
        return .done(response: [slideSnapshots[slideLoads]])
    }
    func getAttachmentFile(link: String, name: String?) async -> DataState<LectureAttachmentFile> { .failure(error: UserFacingError(title: "unused")) }
    func updateLectureUnitCompletion(lectureId: Int, lectureUnitId: Int64, completed: Bool) async -> NetworkResponse { .success }
    func getAssociatedChannel(for lectureId: Int, in courseId: Int) async -> DataState<Channel> { .failure(error: UserFacingError(title: "unused")) }
}

private struct RepeatedLectureDetailHarness: View {
    @ObservedObject var navigation: NavigationController
    let makeModel: (LecturePath) -> LectureDetailViewModel
    var body: some View {
        if let path = navigation.selectedPath as? LecturePath {
            LectureDetailView(viewModel: makeModel(path), target: path.target)
                .id(path.presentationIdentity)
        }
    }
}
