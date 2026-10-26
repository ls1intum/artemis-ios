import Common
import SharedModels
import XCTest
@testable import CourseView

final class ReviewEntryTests: XCTestCase {
    func testActualSDKExercisePayloadsExposeNativeEntryWithExactResultAndSubmission() throws {
        for (exerciseID, submissionID, resultID) in [(10, 10, 1), (11, 12, 2), (12, 13, 3), (13, 14, 4), (14, 15, 5)] {
            let exercise = try decodeExercise(exerciseID)
            let model = ExerciseDetailViewModel(courseId: 7, exerciseId: exerciseID, exercise: .done(response: exercise))
            XCTAssertTrue(model.isFeedbackButtonVisible)
            XCTAssertTrue(model.reviewReferences.contains(where: { $0.submissionID == submissionID && $0.resultID == resultID }), "Missing native entry for exercise \(exerciseID)")
        }
    }

    func testOverviewUsesPrecisionFetchedFromStudentExerciseMetadata() async throws {
        let exercise = try decodeExercise(10)
        let reader = PrecisionReader()
        let model = ExerciseDetailViewModel(courseId: 7, exerciseId: 10, exercise: .done(response: exercise), reviewReader: reader)
        await model.loadReviewMetadata()
        XCTAssertEqual(model.score, "8.25")
    }

    private func decodeExercise(_ id: Int) throws -> Exercise {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: Self.self)
        #endif
        let name = "qa-sdk-exercise-\(id)"
        let url = try XCTUnwrap(bundle.url(forResource: name, withExtension: "json", subdirectory: "Fixtures/StudentQA") ?? bundle.url(forResource: name, withExtension: "json"))
        let decoder = JSONDecoder()
        decoder.dateDecodingStrategy = .customISO8601
        return try decoder.decode(ExerciseDetailsDTO.self, from: Data(contentsOf: url)).exercise
    }
}

private struct PrecisionReader: ReviewReading {
    let isCurrent = true
    func data(_ path: String) async throws -> Data {
        Data(#"{"exercise":{"id":10,"type":"text","course":{"id":7,"accuracyOfScores":2}}}"#.utf8)
    }
}
