import SharedModels
import XCTest
@testable import Quiz

final class TrainingContractTests: XCTestCase {
    func testCapturedRequestsKeepCourseSnapshotAndRejectForeignOrigins() throws {
        let captured = TrainingIdentity(baseURL: URL(string: "https://one.example")!, username: "alice", token: "a", courseID: 8)
        let transport = TrainingTransport(captured: captured, current: { captured })
        let request = try transport.makeRequest(path: "/api/quiz/courses/8/training-questions?page=1&size=10&isNewSession=false", method: "POST", body: JSONEncoder().encode([91, 93]))
        XCTAssertEqual(request.value(forHTTPHeaderField: "Authorization"), "Bearer a")
        XCTAssertEqual(request.httpMethod, "POST")
        XCTAssertEqual(request.httpBody, Data("[91,93]".utf8))
        XCTAssertFalse(request.httpShouldHandleCookies)
        XCTAssertThrowsError(try transport.makeRequest(path: "https://foreign.example/private", method: "GET"))
        XCTAssertThrowsError(try transport.makeRequest(path: "https://user:pass@one.example/private", method: "GET"))
    }
    func testPreSubmitProjectionStripsSolutionsForEveryQuestionType() throws {
        for type in ["multiple-choice", "drag-and-drop", "short-answer"] {
            let json = """
            {"id":1,"isRated":true,"questionIds":[],"isNewSession":false,"quizQuestionWithSolutionDTO":{
            "id":1,"type":"\(type)","explanation":"Secret","answerOptions":[{"id":2,"isCorrect":true,"explanation":"Secret"}],
            "correctMappings":[],"solutions":[{"text":"Secret"}]}}
            """
            let original = try JSONDecoder().decode(DTO.QuizQuestionTraining.self, from: Data(json.utf8))
            let data = try JSONEncoder().encode(TrainingProjection.answering(original))
            let text = try XCTUnwrap(String(data: data, encoding: .utf8))
            XCTAssertFalse(text.contains("Secret"))
            XCTAssertFalse(text.contains("isCorrect"))
            XCTAssertFalse(text.contains("correctMappings"))
        }
    }
    func testShortAnswerSubmissionUsesStableIDAndAllPlaceholderPositions() throws {
        let json = #"{"id":1,"type":"short-answer","text":"[-spot 1] middle [-spot 2]","spots":[{"id":801,"spotNr":1},{"id":802,"spotNr":2}]}"#
        let question = try JSONDecoder().decode(DTO.ShortAnswerQuizQuestionWithSolution.self, from: Data(json.utf8))
        let inputs = TrainingProjection.shortAnswerInputs(question: question)
        XCTAssertEqual(inputs.compactMap { $0.spot?.id }, [801, 802])
        XCTAssertEqual(ShortAnswerReviewPresentation(question: question, answer: nil).answer(number: 1)?.spotID, 801)
    }
    func testMalformedLocationsCannotBeSubmitted() throws {
        let json = #"{"id":1,"quizQuestionWithSolutionDTO":{"type":"drag-and-drop","id":1,"dropLocations":[{"id":5,"posX":0,"posY":0,"width":-10,"height":20}],"dragItems":[{"id":9,"text":"A"}]}}"#
        let question = try JSONDecoder().decode(DTO.QuizQuestionTraining.self, from: Data(json.utf8))
        XCTAssertFalse(TrainingProjection.canAnswer(question))
    }
    func testUnknownAndZeroScoresRemainDistinct() throws {
        let unknown = try JSONDecoder().decode(DTO.SubmittedAnswerAfterEvaluation.self, from: Data(#"{"type":"multiple-choice"}"#.utf8))
        let zero = try JSONDecoder().decode(DTO.SubmittedAnswerAfterEvaluation.self, from: Data(#"{"type":"multiple-choice","scoreInPoints":0}"#.utf8))
        XCTAssertNil(TrainingProjection.points(unknown))
        XCTAssertEqual(TrainingProjection.points(zero), 0)
    }
}
