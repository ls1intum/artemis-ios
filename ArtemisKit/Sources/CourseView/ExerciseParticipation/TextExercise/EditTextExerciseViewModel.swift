import Foundation
import Observation

@MainActor
@Observable
final class EditTextExerciseViewModel {
    let exerciseId: Int
    let participationId: Int
    private(set) var text = ""
    private(set) var context: TextExerciseEditorContext?
    private(set) var submission: TextExerciseEditorSubmission?
    private(set) var isLoading = false
    private(set) var isDraftSaved = false
    private(set) var hasConflict = false
    private(set) var sessionIsCurrent = true
    private(set) var errorMessage: String?
    private(set) var draftError: String?

    private let scope: TextExerciseDraftScope
    private let service: TextExerciseEditingService
    private let store: TextExerciseDraftStore
    private let owner: UUID
    private let isSessionCurrent: () -> Bool
    private var restoredDraft = false
    private var draftReadFailed = false
    private var saveGeneration = 0
    private var revision = 0
    private var saveTask: Task<Void, Never>?

    init(
        exerciseId: Int, participationId: Int, scope: TextExerciseDraftScope,
        service: TextExerciseEditingService, store: TextExerciseDraftStore? = nil,
        isSessionCurrent: @escaping () -> Bool
    ) {
        self.exerciseId = exerciseId
        self.participationId = participationId
        self.scope = scope
        self.service = service
        let store = store ?? .shared
        self.store = store
        self.owner = store.claim(scope: scope)
        self.isSessionCurrent = isSessionCurrent
    }

    var isSubmitting: Bool { store.isSubmitting(scope: scope) }
    var submittedText: String? { submission?.submitted == true ? submission?.text : nil }
    var characterCount: Int { text.utf16.count }
    var isOverLimit: Bool { characterCount > 30_000 }
    var hasUnsubmittedChanges: Bool {
        text != (submission?.text ?? "") || (submission?.submitted != true && !text.isEmpty)
    }
    var canEdit: Bool { sessionIsCurrent && !draftReadFailed && (context != nil || restoredDraft) }
    var canSubmit: Bool {
        canEdit && !isLoading && !isSubmitting && !hasConflict && !isOverLimit &&
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty && hasUnsubmittedChanges &&
        context?.isSubmissionOpen(at: .now) == true
    }
    var latestServerText: String { context?.latestSubmission.text ?? "" }

    func validateSession() {
        let sameAccount = isSessionCurrent()
        sessionIsCurrent = sameAccount && store.owns(scope: scope, owner: owner)
        if !sameAccount {
            errorMessage = R.string.localizable.textExerciseSessionChanged()
        } else if !sessionIsCurrent {
            errorMessage = R.string.localizable.textExerciseEditorChanged()
        }
    }

    func load() async {
        guard !isLoading else { return }
        validateSession()
        guard sessionIsCurrent else { return }
        isLoading = true
        defer { isLoading = false }
        if !restoredDraft {
            do {
                draftReadFailed = false
                if let draft = try await store.load(scope: scope), revision == 0 {
                    text = draft.text
                    submission = draft.baseline
                    restoredDraft = true
                    isDraftSaved = true
                }
            } catch {
                draftReadFailed = true
                draftError = R.string.localizable.textExerciseDraftReadError()
            }
        }
        do {
            let fresh = try await service.load(participationId: participationId)
            validateSession()
            guard sessionIsCurrent else { return }
            try validate(fresh)
            reconcile(fresh)
            errorMessage = nil
        } catch {
            handle(error, submitting: false)
        }
    }

    func updateText(_ value: String) {
        validateSession()
        guard canEdit, value != text else { return }
        text = value
        revision += 1
        persist()
    }

    func flushDraft() async {
        await saveTask?.value
    }

    func submit() async {
        validateSession()
        guard canSubmit, let request = store.beginSubmission(scope: scope) else { return }
        let snapshot = text
        errorMessage = nil
        defer { store.endSubmission(scope: scope, request: request) }
        await flushDraft()
        do {
            validateSession()
            guard sessionIsCurrent else { return }
            let fresh = try await service.load(participationId: participationId)
            validateSession()
            guard sessionIsCurrent else { return }
            try validate(fresh)
            context = fresh
            let latest = fresh.latestSubmission
            // Also resolves an interrupted request whose response never reached this device.
            if latest.text == snapshot, latest.submitted {
                acknowledge(latest)
                return
            }
            if latest.text != (submission?.text ?? "") {
                hasConflict = true
                return
            }
            guard fresh.isSubmissionOpen(at: .now) else {
                errorMessage = R.string.localizable.textExerciseClosed()
                return
            }
            let accepted = try await service.submit(exerciseId: exerciseId, submissionId: latest.id, text: snapshot)
            validateSession()
            guard sessionIsCurrent else { return }
            guard accepted.id != nil, accepted.text == snapshot, accepted.submitted,
                  accepted.participation == nil || accepted.participation?.id == participationId else {
                throw TextExerciseEditingError.invalidResponse
            }
            acknowledge(accepted)
        } catch {
            handle(error, submitting: true)
        }
    }

    /// The student has reviewed the remote answer and chosen to retain this device's work.
    func keepDraft() {
        guard hasConflict else { return }
        submission = context?.latestSubmission
        hasConflict = false
        persist()
    }

    func useServerAnswer() {
        guard hasConflict else { return }
        submission = context?.latestSubmission
        text = submission?.text ?? ""
        revision += 1
        hasConflict = false
        persist()
    }

    func retryDraftSave() {
        persist()
    }

    private func validate(_ fresh: TextExerciseEditorContext) throws {
        guard fresh.id == participationId, fresh.exercise.id == exerciseId,
              fresh.testRun != true, fresh.exercise.exerciseGroup == nil else {
            throw TextExerciseEditingError.invalidResponse
        }
    }

    private func reconcile(_ fresh: TextExerciseEditorContext) {
        context = fresh
        let latest = fresh.latestSubmission
        if !hasUnsubmittedChanges || latest.text == text {
            text = latest.text
            submission = latest
            hasConflict = false
        } else if latest.text != (submission?.text ?? "") {
            hasConflict = true
        } else {
            submission = latest
        }
        persist()
    }

    private func acknowledge(_ accepted: TextExerciseEditorSubmission) {
        submission = accepted
        context?.submissions = [accepted]
        hasConflict = false
        // Persist the CURRENT editor text. A newer edit must never be cleared by an older response.
        persist()
    }

    private func persist() {
        guard let submission, !draftReadFailed, store.owns(scope: scope, owner: owner) else { return }
        isDraftSaved = false
        saveGeneration += 1
        let savedGeneration = saveGeneration
        let write = store.save(TextExerciseDraft(scope: scope, text: text, baseline: submission))
        saveTask = Task { [weak self] in
            let result = await write.value
            guard let self, self.saveGeneration == savedGeneration else { return }
            switch result {
            case .success:
                self.isDraftSaved = true
                self.draftError = nil
            case .failure:
                self.draftError = R.string.localizable.textExerciseDraftWriteError()
            }
        }
    }

    private func handle(_ error: Error, submitting: Bool) {
        validateSession()
        guard sessionIsCurrent else { return }
        if case TextExerciseEditingError.http(let status) = error, status == 401 || status == 403 {
            errorMessage = R.string.localizable.textExerciseAccessError()
        } else {
            errorMessage = submitting ? R.string.localizable.textExerciseSubmitError() : R.string.localizable.textExerciseLoadError()
        }
    }
}
