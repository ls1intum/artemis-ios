import Common
import Navigation
import SharedModels
import XCTest
@testable import CourseView

@MainActor
final class LectureSlideHydrationTests: XCTestCase {
    func testSlimProjectionRetainsValidatedStudentFileAndFreshVisibleIndices() async throws {
        let complete = try details(student: "student.pdf", version: 1)
        let slim = try details(slides: true)
        let service = HydrationLectureService(details: [complete, complete], projection: slim)
        let access = await model(service).refreshSlideAccess(for: target)
        XCTAssertEqual(access.value?.studentVersion, "student.pdf")
        XCTAssertEqual(access.value?.attachment.version, 1)
        XCTAssertEqual(access.value?.originalSlideNumber, 8)
        XCTAssertEqual(access.value?.visibleSlideNumbers, [1, 3, 8])
        XCTAssertEqual(service.detailLoads, 2)
    }

    func testChangedFileOrStudentVariantCannotUseTheOldProjection() async throws {
        let before = try details(student: "student.pdf", version: 1)
        let changes = [
            try details(link: "replacement.pdf", student: "student.pdf", version: 1),
            try details(student: "student.pdf", version: 2),
            try details(student: "replacement-student.pdf", version: 1),
            try details(version: 1)
        ]
        for after in changes {
            let service = HydrationLectureService(details: [before, after], projection: try details(slides: true))
            let access = await model(service).refreshSlideAccess(for: target)
            if case .failure = access {} else { XCTFail("A changed attachment snapshot must be retried") }
        }
    }

    func testProjectionAttachmentIdentityMustMatchCompleteDetails() async throws {
        let complete = try details(student: "student.pdf", version: 1)
        for projection in [try details(link: "other.pdf", slides: true), try details(attachmentID: 11, slides: true)] {
            let service = HydrationLectureService(details: [complete, complete], projection: projection)
            let access = await model(service).refreshSlideAccess(for: target)
            if case .failure = access {} else { XCTFail("The projection must describe the validated file") }
        }
    }

    func testRemovedModernSlideDoesNotFallbackToItsOldOriginalNumber() async throws {
        let complete = try details(student: "student.pdf", version: 1)
        let slim = try details(slides: true, lastSlideID: 99)
        let service = HydrationLectureService(details: [complete, complete], projection: slim)
        let access = await model(service).refreshSlideAccess(for: target)
        if case .failure = access {} else { XCTFail("A replaced modern slide is unavailable") }
    }

    func testFailedDetailsOrChangedSessionCannotExposeAFile() async throws {
        let complete = try details(student: "student.pdf", version: 1)
        let service = HydrationLectureService(details: [], projection: try details(slides: true))
        let failed = await model(service).refreshSlideAccess(for: target)
        if case .failure = failed {} else { XCTFail("Details failure cannot fall back to incomplete metadata") }
        XCTAssertEqual(service.projectionLoads, 0)

        var current = true
        let changed = HydrationLectureService(details: [complete, complete], projection: try details(slides: true))
        changed.didLoadDetails = { current = false }
        let viewModel = model(changed, isCurrent: { current })
        let result = await viewModel.refreshSlideAccess(for: target)
        if case .failure = result {} else { XCTFail("An old account cannot expose a file") }
        XCTAssertEqual(changed.projectionLoads, 0)
    }

    private var target: LectureMediaTarget { .init(unitId: 5, slideId: 43, originalSlideNumber: 8, visibleSlideNumbers: [1, 3, 8]) }
    private func model(_ service: HydrationLectureService, isCurrent: @escaping () -> Bool = { true }) -> LectureDetailViewModel {
        LectureDetailViewModel(course: CourseForOverviewDTO(course: Course(id: 1, courseInformationSharingConfiguration: .communicationAndMessaging)),
                               lectureId: 2, lectureService: service, isCurrent: isCurrent)
    }
    private func details(link: String = "original.pdf", student: String? = nil, version: Int? = nil,
                         attachmentID: Int = 10, slides: Bool = false, lastSlideID: Int = 43) throws -> LectureMediaDetails {
        var attachment: [String: Any] = ["id": attachmentID, "link": link]
        if let student { attachment["studentVersion"] = student }
        if let version { attachment["version"] = version }
        var unit: [String: Any] = ["type": "attachment", "id": 5, "attachment": attachment]
        if slides { unit["slides"] = [["id": 41, "slideNumber": 1], ["id": 42, "slideNumber": 3], ["id": lastSlideID, "slideNumber": 8]] }
        return try JSONDecoder().decode(LectureMediaDetails.self, from: JSONSerialization.data(withJSONObject: ["id": 2, "lectureUnits": [unit]]))
    }
}

@MainActor
private final class HydrationLectureService: LectureService {
    private var snapshots: [LectureMediaDetails]
    private let projection: LectureMediaDetails
    private(set) var detailLoads = 0
    private(set) var projectionLoads = 0
    var didLoadDetails: (() -> Void)?
    init(details: [LectureMediaDetails], projection: LectureMediaDetails) { snapshots = details; self.projection = projection }
    func getLectureDetails(lectureId: Int) async -> DataState<LectureMediaDetails> {
        detailLoads += 1
        didLoadDetails?()
        guard !snapshots.isEmpty else { return .failure(error: UserFacingError(title: "Offline")) }
        return .done(response: snapshots.removeFirst())
    }
    func getLecturesWithSlides(courseId: Int) async -> DataState<[LectureMediaDetails]> {
        projectionLoads += 1
        return .done(response: [projection])
    }
    func getAttachmentFile(link: String, name: String?) async -> DataState<LectureAttachmentFile> { .failure(error: UserFacingError(title: "unused")) }
    func updateLectureUnitCompletion(lectureId: Int, lectureUnitId: Int64, completed: Bool) async -> NetworkResponse { .success }
    func getAssociatedChannel(for lectureId: Int, in courseId: Int) async -> DataState<Channel> { .failure(error: UserFacingError(title: "unused")) }
}
