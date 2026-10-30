import Foundation
import SharedModels
import XCTest
@testable import CourseView

@MainActor
final class TextExerciseEditorTests: XCTestCase {
    func testEditsAreDurableAndNeverAutomaticallySubmitted() async throws {
        let storage = TextExerciseDraftStore(directory: temporaryDirectory())
        let service = TextExerciseServiceStub()
        let model = makeModel(store: storage, service: service)
        await model.load()
        model.updateText("My answer 🧑🏽‍💻")
        await model.flushDraft()

        let restored = makeModel(store: storage, service: service)
        await restored.load()
        await restored.flushDraft()
        XCTAssertEqual(restored.text, "My answer 🧑🏽‍💻")
        XCTAssertTrue(restored.hasUnsubmittedChanges)
        XCTAssertEqual(service.submittedTexts, [])
        XCTAssertTrue(restored.isDraftSaved)
    }

    func testSubmissionAcknowledgesSnapshotAndPreservesNewerEdits() async throws {
        let service = TextExerciseServiceStub()
        let model = makeModel(service: service)
        await model.load()
        model.updateText("First answer")
        service.onSubmit = { model.updateText("Newer draft") }
        await model.submit()
        await model.flushDraft()
        XCTAssertEqual(service.submittedTexts, ["First answer"])
        XCTAssertEqual(model.text, "Newer draft")
        XCTAssertEqual(model.submittedText, "First answer")
        XCTAssertTrue(model.hasUnsubmittedChanges)
        XCTAssertEqual(model.submission?.id, 999, "An assessed submission can receive a new id")
    }

    func testRemoteConflictRequiresExplicitChoice() async throws {
        let service = TextExerciseServiceStub()
        let model = makeModel(service: service)
        await model.load()
        model.updateText("Local draft")
        service.context.submissions = [.init(id: 88, text: "Other device", submitted: true)]
        await model.submit()
        XCTAssertEqual(service.submittedTexts, [])
        XCTAssertEqual(model.text, "Local draft")
        XCTAssertTrue(model.hasConflict)
        model.keepDraft()
        await model.submit()
        XCTAssertEqual(service.submittedTexts, ["Local draft"])
    }

    func testFailedSubmitKeepsDraftForRestart() async throws {
        let storage = TextExerciseDraftStore(directory: temporaryDirectory())
        let service = TextExerciseServiceStub()
        let model = makeModel(store: storage, service: service)
        await model.load()
        model.updateText("Offline answer")
        service.submitError = URLError(.notConnectedToInternet)
        await model.submit()
        await model.flushDraft()
        XCTAssertNotNil(model.errorMessage)
        let restored = makeModel(store: storage, service: service)
        await restored.load()
        XCTAssertEqual(restored.text, "Offline answer")
        XCTAssertTrue(restored.hasUnsubmittedChanges)
    }

    func testSessionChangePreventsSubmissionAndDraftsAreAccountScoped() async throws {
        let storage = TextExerciseDraftStore(directory: temporaryDirectory())
        let service = TextExerciseServiceStub()
        var active = true
        let model = makeModel(store: storage, service: service, isSessionCurrent: { active })
        await model.load()
        model.updateText("Private answer")
        await model.flushDraft()
        active = false
        await model.submit()
        XCTAssertEqual(service.submittedTexts, [])
        let other = makeModel(store: storage, service: service, account: "other")
        await other.load()
        XCTAssertEqual(other.text, "")
    }

    func testUTF16LimitPreservesPastedText() async throws {
        let service = TextExerciseServiceStub()
        let model = makeModel(service: service)
        await model.load()
        let oversized = String(repeating: "😀", count: 15_001)
        model.updateText(oversized)
        await model.submit()
        XCTAssertEqual(model.text, oversized)
        XCTAssertFalse(model.canSubmit)
        XCTAssertEqual(service.submittedTexts, [])
    }

    func testEmptyParticipationAndIndividualDeadline() async throws {
        let service = TextExerciseServiceStub()
        service.context.exercise.dueDate = .now.addingTimeInterval(-100)
        service.context.initializationDate = .now.addingTimeInterval(-200)
        service.context.individualDueDate = .now.addingTimeInterval(100)
        let model = makeModel(service: service)
        await model.load()
        model.updateText("Extended deadline")
        XCTAssertTrue(model.canSubmit)
        await model.submit()
        XCTAssertEqual(service.submittedTexts, ["Extended deadline"])
    }

    func testDiskWriteFailureNeverReportsSaved() async throws {
        let directory = temporaryDirectory()
        try Data("not a directory".utf8).write(to: directory)
        let model = makeModel(store: TextExerciseDraftStore(directory: directory), service: TextExerciseServiceStub())
        await model.load()
        model.updateText("Keep this answer")
        await model.flushDraft()
        XCTAssertEqual(model.text, "Keep this answer")
        XCTAssertFalse(model.isDraftSaved)
        XCTAssertNotNil(model.draftError)
    }

    func testCorruptDraftIsNotOverwrittenByServerLoad() async throws {
        let directory = temporaryDirectory()
        try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
        let scope = TextExerciseDraftScope(server: "https://example.org/", account: "student", exerciseId: 10, participationId: 20)
        let file = directory.appendingPathComponent(scope.filename)
        let original = Data("recoverable damaged draft".utf8)
        try original.write(to: file)
        let model = makeModel(store: TextExerciseDraftStore(directory: directory), service: TextExerciseServiceStub())
        await model.load()
        await model.flushDraft()
        XCTAssertEqual(try Data(contentsOf: file), original)
        XCTAssertFalse(model.canEdit)
        XCTAssertNotNil(model.draftError)
    }

    func testLateStartAndClosedDeadlineKeepDraft() async throws {
        let service = TextExerciseServiceStub()
        service.context.exercise.dueDate = .now.addingTimeInterval(-200)
        service.context.initializationDate = .now.addingTimeInterval(-100)
        let model = makeModel(service: service)
        await model.load()
        model.updateText("Late start")
        XCTAssertTrue(model.canSubmit)
        service.context.initializationDate = .now.addingTimeInterval(-300)
        await model.submit()
        XCTAssertEqual(service.submittedTexts, [])
        XCTAssertEqual(model.text, "Late start")
        XCTAssertFalse(model.canSubmit)
    }

    func testOldEditorCannotOverwriteReopenedDraftOrSubmitConcurrently() async throws {
        let storage = TextExerciseDraftStore(directory: temporaryDirectory())
        let service = TextExerciseServiceStub()
        let original = makeModel(store: storage, service: service)
        await original.load()
        original.updateText("Original answer")
        let started = expectation(description: "Submission started")
        var finish: CheckedContinuation<Void, Never>?
        service.onSubmit = {
            await withCheckedContinuation { continuation in
                finish = continuation
                started.fulfill()
            }
        }
        let request = Task { await original.submit() }
        await fulfillment(of: [started], timeout: 2)
        let reopened = makeModel(store: storage, service: service)
        await reopened.load()
        reopened.updateText("Newer answer")
        await reopened.flushDraft()
        XCTAssertFalse(reopened.canSubmit, "A reopened editor must share the in-flight submission guard")
        finish?.resume()
        await request.value
        let restored = makeModel(store: storage, service: service)
        await restored.load()
        XCTAssertEqual(restored.text, "Newer answer", "An old ACK must not overwrite the reopened editor")
        XCTAssertEqual(service.submittedTexts, ["Original answer"])
    }

    func testCachedExerciseDetailsKeepNewParticipationForOfflineReopening() async {
        let detail = ExerciseDetailViewModel(
            courseId: 1, exerciseId: 10,
            exercise: .done(response: .text(exercise: TextExercise(id: 10))))
        await detail.loadExercise()
        detail.participationId = 20
        await detail.loadExercise()
        XCTAssertEqual(detail.participationId, 20)
    }

    func testRetryRecognizesSubmissionAfterLostResponseWithoutResending() async throws {
        let service = TextExerciseServiceStub()
        let model = makeModel(service: service)
        await model.load()
        model.updateText("Accepted answer")
        service.submitError = URLError(.networkConnectionLost)
        await model.submit()
        service.context.submissions = [.init(id: 999, text: "Accepted answer", submitted: true)]
        await model.submit()
        XCTAssertEqual(service.submittedTexts, ["Accepted answer"])
        XCTAssertFalse(model.hasUnsubmittedChanges)
        XCTAssertEqual(model.submittedText, "Accepted answer")
    }

    func testSessionIdentityDoesNotDependOnRememberedUsername() throws {
        let payload = try JSONSerialization.data(withJSONObject: ["sub": "student"])
            .base64EncodedString().replacingOccurrences(of: "=", with: "")
        let token = "header.\(payload).signature"
        let session = TextExerciseEditingSession.capture(baseURL: URL(string: "https://example.org"), token: token, isLoggedIn: true)
        XCTAssertEqual(session?.account, "student")
        XCTAssertNil(TextExerciseEditingSession.capture(baseURL: URL(string: "https://example.org"), token: token, isLoggedIn: false))
        XCTAssertNil(TextExerciseEditingSession.capture(baseURL: URL(string: "https://example.org"), token: "invalid", isLoggedIn: true))
    }

    func testSessionScopeNeverPersistsURLCredentialsOrQuery() throws {
        let payload = try JSONSerialization.data(withJSONObject: ["sub": "student"]).base64EncodedString()
        let session = try XCTUnwrap(TextExerciseEditingSession.capture(
            baseURL: URL(string: "https://user:password@example.org/artemis/?secret=value#fragment"),
            token: "header.\(payload).signature", isLoggedIn: true))
        XCTAssertEqual(session.baseURL.absoluteString, "https://example.org/artemis/")
        XCTAssertEqual(session.request(path: "api/text/test", method: "GET").url?.absoluteString, "https://example.org/artemis/api/text/test")
    }

    private func makeModel(
        store: TextExerciseDraftStore? = nil,
        service: TextExerciseServiceStub,
        account: String = "student",
        isSessionCurrent: @escaping () -> Bool = { true }
    ) -> EditTextExerciseViewModel {
        EditTextExerciseViewModel(
            exerciseId: 10, participationId: 20,
            scope: TextExerciseDraftScope(server: "https://example.org/", account: account, exerciseId: 10, participationId: 20),
            service: service, store: store ?? TextExerciseDraftStore(directory: temporaryDirectory()),
            isSessionCurrent: isSessionCurrent)
    }

    private func temporaryDirectory() -> URL {
        let url = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString)
        addTeardownBlock { try? FileManager.default.removeItem(at: url) }
        return url
    }
}

@MainActor
private final class TextExerciseServiceStub: TextExerciseEditingService {
    var context = TextExerciseEditorContext(
        id: 20, initializationDate: .now, exercise: .init(id: 10), submissions: [])
    var submittedTexts: [String] = []
    var submitError: Error?
    var onSubmit: (() async -> Void)?

    func load(participationId: Int) async throws -> TextExerciseEditorContext { context }

    func submit(exerciseId: Int, submissionId: Int?, text: String) async throws -> TextExerciseEditorSubmission {
        submittedTexts.append(text)
        await onSubmit?()
        if let submitError { throw submitError }
        let result = TextExerciseEditorSubmission(id: 999, text: text, submitted: true)
        context.submissions = [result]
        return result
    }
}
