import SwiftUI
import UserStore

/// Starting a participation requires a fresh server response before a draft can be scoped to it.
struct TextExerciseEntryView: View {
    let exerciseId: Int
    @Binding var participationId: Int?
    @State private var model: EditTextExerciseViewModel?
    @State private var opening = false
    @State private var failed = false
    @State private var errorMessage = R.string.localizable.textExerciseLoadError()

    var body: some View {
        Group {
            if let model {
                EditTextExerciseView(viewModel: model)
            } else if failed {
                ContentUnavailableView {
                    Label(R.string.localizable.textExerciseAnswer(), systemImage: "doc.text")
                } description: {
                    Text(errorMessage)
                } actions: {
                    Button(R.string.localizable.textExerciseRetry()) { Task { await open() } }
                        .disabled(opening)
                }
            } else {
                ProgressView(R.string.localizable.textExerciseOpening())
            }
        }
        .task { await open() }
    }

    private func open() async {
        guard model == nil, !opening else { return }
        opening = true
        failed = false
        defer { opening = false }
        guard let session = TextExerciseEditingSession.current else {
            errorMessage = R.string.localizable.textExerciseSessionChanged()
            failed = true
            return
        }
        do {
            let service = NativeTextExerciseService(session: session)
            let participationId: Int
            if let existing = self.participationId {
                participationId = existing
            } else {
                participationId = try await service.open(exerciseId: exerciseId)
            }
            guard TextExerciseEditingSession.current == session else {
                failed = true
                return
            }
            self.participationId = participationId
            model = EditTextExerciseViewModel(
                exerciseId: exerciseId, participationId: participationId,
                scope: TextExerciseDraftScope(server: session.baseURL.absoluteString, account: session.account,
                                              exerciseId: exerciseId, participationId: participationId),
                service: service, isSessionCurrent: { TextExerciseEditingSession.current == session })
        } catch {
            if case TextExerciseEditingError.http(let status) = error, status == 401 || status == 403 {
                errorMessage = R.string.localizable.textExerciseAccessError()
            } else {
                errorMessage = R.string.localizable.textExerciseLoadError()
            }
            failed = true
        }
    }
}
