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
        let first = try JSONDecoder().decode(LectureMediaDetails.self, from: Data(#"""
        {"id":2,"lectureUnits":[
        {"type":"attachment","id":5,
        "attachment":{"id":10,"studentVersion":"new-student.pdf"},
        "slides":[{"id":41,"slideNumber":1},{"id":99,"slideNumber":2},{"id":42,"slideNumber":3},{"id":43,"slideNumber":8}]}]}
        """#.utf8))
        let hidden = try JSONDecoder().decode(LectureMediaDetails.self, from: Data(#"""
        {"id":2,"lectureUnits":[
        {"type":"attachment","id":5,
        "attachment":{"id":10,"studentVersion":"later-student.pdf"},
        "slides":[{"id":41,"slideNumber":1}]}]}
        """#.utf8))
        service.slideSnapshots = [first, hidden]
        service.detailSnapshots = [first, first, first, first]
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

    func testCompletionPublishesAfterTheRequestSettlesSoTheOriginCanRefresh() async throws {
        let service = RecoveryLectureService()
        service.failsFirstLoad = false
        service.delaysCompletion = true
        let model = LectureDetailViewModel(course: CourseForOverviewDTO(course: Course(id: 1, courseInformationSharingConfiguration: .communicationAndMessaging)), lectureId: 2,
                                           lectureService: service, isCurrent: { true })
        await model.loadLecture()
        let unit = try XCTUnwrap(model.lecture.value?.lectureUnits?.first)
        let event = expectation(forNotification: Notification.Name("lectureUnitCompletionDidChange"), object: nil) { notification in
            notification.userInfo?["courseId"] as? Int == 1 && notification.userInfo?["lectureId"] as? Int == 2
        }
        let update = Task { await model.updateLectureUnitCompletion(lectureUnit: unit, completed: true) }
        for _ in 0..<100 where service.completion == nil { await Task.yield() }
        let completion = try XCTUnwrap(service.completion)
        // Back's initial overview refresh can complete before the POST does.
        await model.loadLecture()
        completion.resume(returning: .success)
        _ = await update.value
        await fulfillment(of: [event], timeout: 0.2)
    }

    func testCompletionFailureIsVisibleOnTheMediaPage() async throws {
        let service = RecoveryLectureService()
        service.failsFirstLoad = false
        service.failsCompletion = true
        let model = LectureDetailViewModel(course: CourseForOverviewDTO(course: Course(id: 1, courseInformationSharingConfiguration: .communicationAndMessaging)), lectureId: 2,
                                           lectureService: service, isCurrent: { true })
        let path = LectureMediaPath(courseId: 1, lectureId: 2, target: .init(unitId: 5))
        let host = UIHostingController(rootView: NavigationStack { LectureMediaPage(viewModel: model, path: path) })
        let window = try makeTestWindow(frame: CGRect(x: 0, y: 0, width: 1000, height: 800))
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { host.dismiss(animated: false); window.isHidden = true; window.rootViewController = nil }
        for _ in 0..<100 where model.targetPresentation == nil { try await Task.sleep(for: .milliseconds(10)) }
        let unit = try XCTUnwrap(model.targetPresentation?.unit)
        _ = await model.updateLectureUnitCompletion(lectureUnit: unit, completed: true)
        for _ in 0..<100 where host.presentedViewController == nil { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertTrue(model.showError)
        XCTAssertNotNil(host.presentedViewController, "A rejected completion must show the error on the visible page")
    }

    func testRetryDisplaysTheRequestedUnitOnAFullPageWithoutPresentingASheet() async throws {
        let service = RecoveryLectureService()
        let model = LectureDetailViewModel(course: CourseForOverviewDTO(course: Course(id: 1, courseInformationSharingConfiguration: .communicationAndMessaging)), lectureId: 2,
                                           lectureService: service, isCurrent: { true })
        let path = LectureMediaPath(courseId: 1, lectureId: 2, target: .init(unitId: 5, page: 3))
        let host = UIHostingController(rootView: NavigationStack { LectureMediaPage(viewModel: model, path: path) })
        let window = try makeTestWindow(frame: CGRect(x: 0, y: 0, width: 1000, height: 800))
        window.rootViewController = host
        window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        for _ in 0..<100 where service.loads == 0 { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertNil(model.targetPresentation)
        await model.retryTarget() // The operation invoked by the page's Retry action.
        for _ in 0..<100 where model.targetPresentation == nil { try await Task.sleep(for: .milliseconds(10)) }
        XCTAssertEqual(model.targetPresentation?.target?.page, 3)
        XCTAssertEqual(model.targetPresentation?.unit.baseUnit.name, "Requested unit")
        XCTAssertNil(host.presentedViewController, "Study content belongs to the navigation page, not a modal")
        XCTAssertEqual(host.view.bounds.width, window.bounds.width)
    }
}

@MainActor
private final class RecoveryLectureService: LectureService {
    var failsFirstLoad = true
    var failsCompletion = false
    var delaysCompletion = false
    var completion: CheckedContinuation<NetworkResponse, Never>?
    var loads = 0
    var slideLoads = 0
    var slideSnapshots: [LectureMediaDetails] = []
    var detailSnapshots: [LectureMediaDetails] = []
    func getLectureDetails(lectureId: Int) async -> DataState<LectureMediaDetails> {
        loads += 1
        if !detailSnapshots.isEmpty { return .done(response: detailSnapshots.removeFirst()) }
        if failsFirstLoad, loads == 1 { return .failure(error: UserFacingError(title: "Offline")) }
        let data = Data(#"{"id":2,"lectureUnits":[{"type":"text","id":5,"name":"Requested unit","content":"Requested unit content","visibleToStudents":true,"completed":true}]}"#.utf8)
        do { return .done(response: try JSONDecoder().decode(LectureMediaDetails.self, from: data)) } catch {
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
    func updateLectureUnitCompletion(lectureId: Int, lectureUnitId: Int64, completed: Bool) async -> NetworkResponse {
        if delaysCompletion { return await withCheckedContinuation { completion = $0 } }
        if failsCompletion { return .failure(error: UserFacingError(title: "Offline")) }
        return .success
    }
    func getAssociatedChannel(for lectureId: Int, in courseId: Int) async -> DataState<Channel> { .failure(error: UserFacingError(title: "unused")) }
}
