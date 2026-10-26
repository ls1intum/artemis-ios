import DesignLibrary
import Foundation
import Quiz
import SharedModels
import SwiftUI

extension ResultReviewPage {
    func fileWork(_ document: ReviewDocument) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            if let file = document.submission.filePath {
                Label(URL(string: file)?.lastPathComponent ?? file, systemImage: "doc")
                    .font(.headline).textSelection(.enabled)
                if let previewURL {
                    QuickLookController(url: previewURL).frame(minHeight: 520)
                } else {
                    Button(ReviewCopy.text("review.openFile")) { Task { await loadFile(file) } }
                        .buttonStyle(.borderedProminent).disabled(fileLoading)
                    if fileLoading { ProgressView() }
                    if let previewError { Text(previewError).foregroundStyle(.secondary) }
                }
            } else { unavailable("review.sourceUnavailable") }
        }
    }

    func programmingWork(_ document: ReviewDocument) -> some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(ReviewCopy.text("review.assessedCode")).font(.title2.bold())
            if let commit = document.submission.commitHash {
                Text(commit).font(.caption.monospaced()).textSelection(.enabled)
            }
            if let sourceName, let source {
                Text(sourceName).font(.headline).textSelection(.enabled)
                ReviewCodeText(text: source, location: selectedFeedback.flatMap { index in
                    guard document.feedback.indices.contains(index),
                      let reference = document.feedback[index].sourceReference else { return nil }
                    return ReviewCodeLocation(reference: reference)
                })
            } else { unavailable("review.selectCodeFeedback") }
            if sourceLoading { ProgressView() }
            if let sourceError { Text(sourceError).foregroundStyle(.secondary) }
            DisclosureGroup(ReviewCopy.text("review.logs")) {
                if let logs {
                    if logs.isEmpty { unavailable("review.noLogs") }
                    ForEach(Array(logs.enumerated()), id: \.offset) { _, entry in
                        VStack(alignment: .leading, spacing: 4) {
                            if let time = entry.time { Text(time).font(.caption).foregroundStyle(.secondary) }
                            Text(entry.log ?? "").font(.system(.callout, design: .monospaced)).textSelection(.enabled)
                        }.frame(maxWidth: .infinity, alignment: .leading).padding(.vertical, 4)
                    }
                } else {
                    Button(ReviewCopy.text("review.loadLogs")) { Task { await loadLogs() } }.disabled(logsLoading)
                    if logsLoading { ProgressView() }
                    if let logsError { Text(logsError).foregroundStyle(.secondary) }
                }
            }
        }
    }

    @ViewBuilder
    func quizWork(_ document: ReviewDocument) -> some View {
        switch document.quiz {
        case .afterQuizEnd(let participation):
            if let submission = participation.submissions?.first(where: { $0.id == Int64(reference.submissionID) }),
               let questions = participation.exercise?.quizQuestions {
                QuizResultReview(questions: questions, answers: submission.submittedAnswers ?? [])
            } else { unavailable("review.sourceUnavailable") }
        case .liveQuiz:
            unavailable("review.quizWithheld")
        default: unavailable("review.sourceUnavailable")
        }
    }

    @MainActor
    func loadFile(_ path: String) async {
        guard let transport, transport.isCurrent else { clear(); return }
        let selected = reference
        let generation = self.generation
        fileLoading = true; previewError = nil
        defer { if self.generation == generation { fileLoading = false } }
        do {
            let normalized: String
            if path.hasPrefix("/api/") || path.hasPrefix("api/") || path.hasPrefix("http") {
                normalized = path
            } else {
                normalized = "/api/core/files/" + path.trimmingCharacters(in: CharacterSet(charactersIn: "/"))
            }
            let data = try await transport.data(normalized)
            guard reference == selected, self.generation == generation, transport.isCurrent else { return }
            let directory = FileManager.default.temporaryDirectory.appendingPathComponent(UUID().uuidString, isDirectory: true)
            try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
            let name = URL(string: path)?.lastPathComponent ?? "submission"
            let url = directory.appendingPathComponent(name.isEmpty ? "submission" : name)
            try data.write(to: url, options: [.atomic, .completeFileProtection])
            guard reference == selected, self.generation == generation, transport.isCurrent else { try? FileManager.default.removeItem(at: directory); return }
            previewURL = url
        } catch { handle(error, selected: selected, generation: generation) { previewError = $0 } }
    }

    @MainActor
    func loadSource(_ name: String) async {
        guard let transport, transport.isCurrent, let commit = document?.submission.commitHash else {
            sourceError = ReviewCopy.text("review.sourceUnavailable")
            return
        }
        let selected = reference
        let generation = self.generation
        sourceLoading = true; sourceError = nil
        defer { if self.generation == generation { sourceLoading = false } }
        do {
            let path = try ReviewSourcePath.file(reference: selected, commit: commit, name: name)
            let data = try await transport.data(path)
            guard reference == selected, self.generation == generation, transport.isCurrent else { return }
            guard let text = String(data: data, encoding: .utf8), !data.contains(0) else { throw ReviewError.identity }
            sourceName = name; source = text
        } catch { handle(error, selected: selected, generation: generation) { sourceError = ReviewCopy.text("review.sourceUnavailable") + " " + $0 } }
    }

    @MainActor
    func loadLogs() async {
        guard let transport, transport.isCurrent else { clear(); return }
        let selected = reference
        let generation = self.generation
        logsLoading = true; logsError = nil
        defer { if self.generation == generation { logsLoading = false } }
        do {
            let loaded = try await transport.read([ReviewBuildLog].self, path: "/api/programming/participations/\(selected.participationID)/buildlogs?resultId=\(selected.resultID)")
            guard reference == selected, self.generation == generation, transport.isCurrent else { return }
            logs = loaded
        } catch { handle(error, selected: selected, generation: generation) { logsError = $0 } }
    }

    @MainActor
    func loadLong(_ index: Int) async {
        guard let transport, transport.isCurrent, let document, document.feedback.indices.contains(index), let id = document.feedback[index].id else { return }
        let selected = reference
        let generation = self.generation
        longLoading.insert(index); longErrors.remove(index)
        defer { if self.generation == generation { longLoading.remove(index) } }
        do {
            let data = try await transport.data("/api/assessment/feedbacks/\(id)/long-feedback")
            guard reference == selected, self.generation == generation, transport.isCurrent, self.document?.feedback.indices.contains(index) == true else { return }
            guard let fullMessage = String(bytes: data, encoding: .utf8) else { throw ReviewError.identity }
            self.document?.feedback[index].detailText = fullMessage
            self.document?.feedback[index].hasLongFeedbackText = false
        } catch { handle(error, selected: selected, generation: generation) { _ in longErrors.insert(index) } }
    }

    @MainActor
    func loadSolution() async {
        guard let transport, transport.isCurrent else { clear(); return }
        let selected = reference
        let generation = self.generation
        solutionLoading = true; solutionError = nil
        defer { if self.generation == generation { solutionLoading = false } }
        do {
            let loaded = try await transport.read(ReviewExercise.self, path: "/api/exercise/exercises/\(selected.exerciseID)/example-solution")
            guard reference == selected, self.generation == generation, transport.isCurrent, loaded.id == selected.exerciseID else { return }
            solution = loaded
        } catch {
            // A solution can be independently withheld while the selected result remains available.
            guard reference == selected, self.generation == generation, transport.isCurrent else { return }
            solutionError = ReviewCopy.text("review.solutionUnavailable")
        }
    }

    @MainActor
    func handle(_ error: Error, selected: ReviewReference, generation: UUID, display: (String) -> Void) {
        guard reference == selected, self.generation == generation else { return }
        if !((transport?.isCurrent) ?? false) { clear(); return }
        if case ReviewError.denied = error { clear(); self.error = ReviewCopy.text("review.denied"); return }
        display(ReviewCopy.error(error))
    }
}
