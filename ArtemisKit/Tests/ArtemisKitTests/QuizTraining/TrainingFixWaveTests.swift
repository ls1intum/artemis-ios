import SharedModels
import SwiftUI
import UserStore
import XCTest
@testable import Quiz

@MainActor
final class TrainingFixWaveTests: XCTestCase {
    func testMixedFirstPageCannotPresentOrSubmit() async throws {
        let service = TrainingStub(pages: [.init(questions: [try question(1), try question(2, rated: false)], hasNext: true)])
        let model = QuizTrainingViewModel(courseId: 7, transport: service)
        await model.loadQuestions()
        XCTAssertEqual(model.phase, .pageFailure)
        XCTAssertNil(model.currentQuestion)
        await model.submitAnswer(questionId: 1, isRated: true, answer: mcAnswer)
        XCTAssertEqual(service.submits, 0)
    }
    func testInconsistentSecondPageCannotAdvanceCursorAndCanRetry() async throws {
        let service = TrainingStub(pages: [
            .init(questions: [try question(1)], hasNext: true),
            .init(questions: [try question(2), try question(3, snapshot: [999])], hasNext: true),
            .init(questions: [try question(2)], hasNext: false)
        ])
        let model = QuizTrainingViewModel(courseId: 7, transport: service)
        await model.loadQuestions(); await model.skip()
        XCTAssertEqual(model.phase, .pageFailure)
        XCTAssertNil(model.currentQuestion)
        await model.retryPage()
        XCTAssertEqual(service.requests.suffix(2).map(\.page), [1, 1])
        XCTAssertEqual(model.currentQuestion?.id, 2)
    }
    func testHomogeneousChangedContinuationMetadataIsRejected() async throws {
        for changed in [try question(2, snapshot: [999]), try question(2, fresh: true), try question(2, rated: false)] {
            let service = TrainingStub(pages: [.init(questions: [try question(1)], hasNext: true), .init(questions: [changed], hasNext: false)])
            let model = QuizTrainingViewModel(courseId: 7, transport: service)
            await model.loadQuestions(); await model.skip()
            XCTAssertEqual(model.phase, .pageFailure)
            XCTAssertNil(model.currentQuestion)
        }
    }
    func testEvaluatedQuestionSupersedesFetchedSolutionsForAllNativeTypes() throws {
        for type in ["multiple-choice", "drag-and-drop", "short-answer"] {
            let fetched = try JSONDecoder().decode(DTO.QuizQuestionTraining.self, from: Data("""
            {"id":1,"isRated":true,"quizQuestionWithSolutionDTO":{"id":1,"type":"\(type)","explanation":"old",
            "answerOptions":[{"id":2,"isCorrect":false}],"correctMappings":[]}}
            """.utf8))
            let evaluated = try JSONDecoder().decode(DTO.SubmittedAnswerAfterEvaluation.self, from: Data("""
            {"type":"\(type)","quizQuestion":{"id":1,"type":"\(type)","explanation":"current",
            "answerOptions":[{"id":2,"isCorrect":true}],"correctMappings":[{"dragItem":{"id":8},"dropLocation":{"id":9},"spot":{"id":913},"solution":{"text":"updated"}}]}}
            """.utf8))
            let presentation = TrainingQuestionPresentation(question: fetched, evaluation: evaluated, draft: nil)
            XCTAssertEqual(QuizReviewQuestionContent(presentation.question.quizQuestionWithSolutionDTO).explanation, "current")
            switch presentation.question.quizQuestionWithSolutionDTO {
            case .multipleChoice(let question): XCTAssertEqual(question.answerOptions?.first?.isCorrect, true)
            case .dragAndDrop(let question): XCTAssertEqual(question.correctMappings?.first?.dragItem?.id, 8)
            case .shortAnswer(let question): XCTAssertEqual(question.correctMappings?.first?.solution?.text, "updated")
            }
        }
    }
    func testMissingEvaluatedQuestionNeverReusesOldGradingAndKeepsFrozenAnswer() throws {
        let fetched = try question(1)
        let evaluation = try JSONDecoder().decode(DTO.SubmittedAnswerAfterEvaluation.self, from: Data(#"{"type":"multiple-choice","scoreInPoints":0}"#.utf8))
        let presentation = TrainingQuestionPresentation(question: fetched, evaluation: evaluation, draft: mcAnswer)
        XCTAssertNil(QuizReviewQuestionContent(presentation.question.quizQuestionWithSolutionDTO).explanation)
        guard case .multipleChoice(let answer) = presentation.answer else { XCTFail("Frozen selection missing"); return }
        XCTAssertEqual(answer.selectedOptions?.first?.id, 2)
    }
    func testLeagueAndCurrentRankAreAvailableOutsidePublicSlice() async throws {
        let service = TrainingOverviewStub(settings: false)
        let overview = TrainingOverview(transport: service)
        let entry = try JSONDecoder().decode(TrainingLeaderboardEntry.self, from: Data(#"{"selectedLeague":5,"rank":72,"score":25}"#.utf8))
        let league = try XCTUnwrap(TrainingLeague(selectedLeague: entry.selectedLeague))
        XCTAssertEqual(league.name, "Bronze")
        XCTAssertEqual(league.lowerBound, 0)
        XCTAssertEqual(league.upperBound, 50)
        service.entry = entry; await overview.load()
        XCTAssertEqual(overview.currentRank, 72)
        XCTAssertNil(TrainingLeague(selectedLeague: nil))
        XCTAssertNil(TrainingLeague(selectedLeague: 99))
        XCTAssertEqual(overview.data?.leaderboardEntries?.count ?? 0, 0)
    }
    func testChangedConfirmedProgressRefreshesOnlyGETAndRetainsOnboardingAndDraft() async throws {
        let service = TrainingOverviewStub(settings: nil)
        let overview = TrainingOverview(transport: service)
        await overview.load()
        let count = service.reads
        let session = QuizTrainingViewModel(courseId: 7, transport: TrainingStub(pages: [.init(questions: [try question(1)], hasNext: false)]))
        await session.loadQuestions(); session.updateDraft(mcAnswer)
        await session.submitAnswer(questionId: 1, isRated: true, answer: mcAnswer)
        await overview.refreshIfNeeded(after: session.progressRevision)
        XCTAssertEqual(session.phase, .evaluated)
        XCTAssertEqual(session.currentQuestion?.id, 1)
        XCTAssertNotNil(session.draft)
        session.finish()
        XCTAssertEqual(session.progressRevision, 1)
        XCTAssertEqual(service.reads, count + 1)
        XCTAssertTrue(overview.needsPrivacyChoice)
        await overview.refreshIfNeeded(after: 1)
        XCTAssertEqual(service.reads, count + 1)
        XCTAssertEqual(service.writes, [])
    }
    func testRealSDKNonrememberedLoginCapturesAuthenticatedAccountAndAssembledEntryLoads() async throws {
        let account = UserSessionFactory.shared
        let oldLoggedIn = account.isLoggedIn; let oldUsername = account.username; let oldInstitution = account.institution
        let oldUserData = UserDefaults.standard.data(forKey: "User")
        defer {
            account.saveUsername(username: oldUsername); account.saveInstitution(identifier: oldInstitution)
            account.setUserLoggedIn(isLoggedIn: oldLoggedIn)
            if let oldUserData { UserDefaults.standard.set(oldUserData, forKey: "User") } else { UserDefaults.standard.removeObject(forKey: "User") }
        }
        account.saveInstitution(identifier: .custom(URL(string: "https://training.example")!))
        account.saveUsername(username: nil); account.setUserLoggedIn(isLoggedIn: true)
        var currentToken: String? = "synthetic-training-token"
        account.user = .mock
        let identity = try XCTUnwrap(TrainingIdentity.current(courseID: 14, token: { currentToken }))
        XCTAssertEqual(identity.username, Account.mock.login)
        XCTAssertNil(account.username, "Remembered-login preference must stay unset")
        let loaded = expectation(description: "Real assembled entry performs scoped overview GET")
        TrainingURLProtocol.handler = { request in
            if request.url?.path.hasSuffix("training/leaderboard") == true { loaded.fulfill() }
            let json = request.url?.path.hasSuffix("leaderboard-settings") == true ? #"{"showInLeaderboard":false}"# : #"{"hasUserSetSettings":false,"currentUserEntry":{},"leaderboardEntries":[]}"#
            return (200, [:], Data(json.utf8))
        }
        defer { TrainingURLProtocol.handler = nil }
        let view = TrainingFeatureView(courseId: 14, scorePrecision: 1, account: account, token: { currentToken }) { captured in
            let configuration = URLSessionConfiguration.ephemeral; configuration.protocolClasses = [TrainingURLProtocol.self]
            return TrainingTransport(captured: captured, current: { TrainingIdentity.current(courseID: 14, token: { currentToken }) }, configuration: configuration)
        }
        let host = UIHostingController(rootView: NavigationStack { view })
        let window = try makeTestWindow(frame: CGRect(x: 0, y: 0, width: 390, height: 844))
        window.rootViewController = host; window.makeKeyAndVisible()
        defer { window.isHidden = true; window.rootViewController = nil }
        await fulfillment(of: [loaded], timeout: 3)
        XCTAssertEqual(TrainingIdentity.current(courseID: 14, token: { currentToken }), identity)
        currentToken = nil
        XCTAssertNil(TrainingIdentity.current(courseID: 14, token: { currentToken }), "A missing JWT must still block the capture")
        account.setUserLoggedIn(isLoggedIn: false)
        XCTAssertNil(TrainingIdentity.current(courseID: 14, token: { "synthetic-training-token" }))
    }
    private var mcAnswer: DTO.SubmittedAnswerFromLiveClient {
        .multipleChoice(.init(quizQuestion: .init(id: 1), selectedOptions: [.init(id: 2)], _type: .multipleChoice))
    }
    private func question(_ id: Int, rated: Bool = true, snapshot: [Int] = [91], fresh: Bool = false) throws -> DTO.QuizQuestionTraining {
        let ids = snapshot.map(String.init).joined(separator: ",")
        return try JSONDecoder().decode(DTO.QuizQuestionTraining.self, from: Data("""
        {"id":\(id),"isRated":\(rated),"isNewSession":\(fresh),"questionIds":[\(ids)],
        "quizQuestionWithSolutionDTO":{"id":\(id),"type":"multiple-choice","explanation":"old","answerOptions":[{"id":2,"isCorrect":true}]}}
        """.utf8))
    }
}
