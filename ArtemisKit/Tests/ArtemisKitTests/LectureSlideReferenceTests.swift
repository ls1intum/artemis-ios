import XCTest
import SharedModels
@testable import Messages
@testable import CourseView
@testable import Navigation

final class LectureSlideReferenceTests: XCTestCase {
    func testLectureDetailsRetainTheActualStudentFilename() throws {
        let details = try JSONDecoder().decode(LectureMediaDetails.self, from: Data(#"{"id":2,"lectureUnits":[{"type":"attachment","id":5,"attachment":{"id":10,"link":"attachments/unit/5/original.pdf","studentVersion":"attachments/unit/5/student/visible-pages.pdf"}}]}"#.utf8))
        XCTAssertEqual(details.lecture.id, 2)
        XCTAssertEqual(details.studentVersions[10], "attachments/unit/5/student/visible-pages.pdf")
    }

    func testFreshSnapshotReplacesOldVisibleIndicesAndBindsItsStudentFile() throws {
        let details = try JSONDecoder().decode(LectureMediaDetails.self, from: Data(#"{"id":2,"lectureUnits":[{"type":"attachment","id":5,"attachment":{"id":10,"link":"original.pdf","studentVersion":"fresh-student.pdf"},"slides":[{"id":41,"slideNumber":1},{"id":99,"slideNumber":2},{"id":42,"slideNumber":3},{"id":43,"slideNumber":8}]}]}"#.utf8))
        let target = LectureMediaTarget(unitId: 5, slideId: 43, originalSlideNumber: 8, visibleSlideNumbers: [1, 3, 8])
        let access = try XCTUnwrap(LectureSlideAccess.resolve(target: target, details: details))
        XCTAssertEqual(access.visibleSlideNumbers, [1, 2, 3, 8])
        XCTAssertEqual(access.studentVersion, "fresh-student.pdf")
        XCTAssertEqual(LectureMediaSlidePage.page(original: access.originalSlideNumber, visibleNumbers: access.visibleSlideNumbers, studentVersion: true), 4)
    }

    func testModernSlideIdentityMustStillExistEvenIfOriginalNumberWasReused() throws {
        let details = try JSONDecoder().decode(LectureMediaDetails.self, from: Data(#"{"id":2,"lectureUnits":[{"type":"attachment","id":5,"attachment":{"id":10,"link":"original.pdf"},"slides":[{"id":44,"slideNumber":8}]}]}"#.utf8))
        XCTAssertNil(LectureSlideAccess.resolve(target: .init(unitId: 5, slideId: 43, originalSlideNumber: 8, visibleSlideNumbers: [8]), details: details))
        XCTAssertNotNil(LectureSlideAccess.resolve(target: .init(unitId: 5, originalSlideNumber: 8), details: details))
    }

    func testStudentPDFMapsVisibleSlideNumbersAndRejectsHiddenTarget() {
        XCTAssertEqual(LectureMediaSlidePage.page(original: 8, visibleNumbers: [8, 1, 3], studentVersion: true), 3)
        XCTAssertEqual(LectureMediaSlidePage.page(original: 8, visibleNumbers: [1, 3, 8], studentVersion: false), 8)
        XCTAssertNil(LectureMediaSlidePage.page(original: 2, visibleNumbers: [1, 3, 8], studentVersion: true))
        XCTAssertNil(LectureMediaSlidePage.page(original: 2, visibleNumbers: [1, 3, 8], studentVersion: false))
    }

    func testResolvedReferenceCannotClampToAnUnrelatedDocumentPage() {
        XCTAssertEqual(LectureMediaSlidePage.documentIndex(page: 3, pageCount: 8), 2)
        XCTAssertNil(LectureMediaSlidePage.documentIndex(page: 3, pageCount: 2))
        XCTAssertNil(LectureMediaSlidePage.documentIndex(page: 0, pageCount: 8))
    }

    func testModernReferenceRendersAsAnActionableSlideLink() {
        XCTAssertEqual(LectureSlideReference.rendering("See [slide]Inheritance(#42)[/slide]."), "See [Inheritance](mention://slide-id/42).")
        XCTAssertEqual(LectureSlideReference.rendering("Unrelated ![image](image.png)"), "Unrelated ![image](image.png)")
    }

    func testModernIdAndLegacyNumberResolveToActualUnitWithOriginalNumber() throws {
        let lecture = try JSONDecoder().decode(Lecture.self, from: Data(#"{"id":2,"lectureUnits":[{"type":"attachment","id":5,"attachment":{"id":10,"link":"/api/core/files/attachment-unit/5/slides.pdf"},"slides":[{"id":41,"slideNumber":1},{"id":42,"slideNumber":3},{"id":43,"slideNumber":8}]}]}"#.utf8))
        let modern = LectureSlideReference.resolve(slideId: 43, unitId: nil, number: nil, lectures: [lecture])
        XCTAssertEqual(modern?.lecture.id, 2)
        XCTAssertEqual(modern?.target.unitId, 5)
        XCTAssertEqual(modern?.target.slideId, 43)
        XCTAssertEqual(modern?.target.originalSlideNumber, 8)
        XCTAssertEqual(modern?.target.visibleSlideNumbers, [1, 3, 8])
        let legacy = LectureSlideReference.resolve(slideId: nil, unitId: 5, number: 3, lectures: [lecture])
        XCTAssertEqual(legacy?.target.originalSlideNumber, 3)
        XCTAssertNil(LectureSlideReference.resolve(slideId: nil, unitId: 5, number: 2, lectures: [lecture]))
        XCTAssertNil(LectureSlideReference.resolve(slideId: 99, unitId: nil, number: nil, lectures: [lecture]))
        XCTAssertEqual(LectureMediaTarget(attachmentId: 10).resolve(in: lecture.lectureUnits ?? [])?.id, 5)
        XCTAssertEqual(LectureMediaTarget(attachmentFilename: "slides.pdf").resolve(in: lecture.lectureUnits ?? [])?.id, 5)
        XCTAssertNil(LectureMediaTarget(unitId: 999).resolve(in: lecture.lectureUnits ?? []))
    }
}
