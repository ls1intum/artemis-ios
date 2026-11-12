import CryptoKit
import Foundation
import Observation

struct TextExerciseDraftScope: Codable, Equatable, Sendable {
    let server: String
    let account: String
    let exerciseId: Int
    let participationId: Int

    var filename: String {
        let encoder = JSONEncoder()
        encoder.outputFormatting = .sortedKeys
        let data = (try? encoder.encode(self)) ?? Data()
        return SHA256.hash(data: data).map { String(format: "%02x", $0) }.joined() + ".json"
    }
}

struct TextExerciseDraft: Codable, Sendable {
    let scope: TextExerciseDraftScope
    let text: String
    let baseline: TextExerciseEditorSubmission
}

/// The queue belongs to the app, not the editor's view task. Leaving a page cannot cancel a pending disk write.
@MainActor
@Observable
final class TextExerciseDraftStore {
    static let shared = TextExerciseDraftStore(directory: URL.applicationSupportDirectory.appendingPathComponent("TextExerciseDrafts", isDirectory: true))
    private let directory: URL
    private var tail: Task<Void, Never>?
    private var owners: [String: UUID] = [:]
    private var submissions: [String: UUID] = [:]

    func claim(scope: TextExerciseDraftScope) -> UUID {
        let owner = UUID()
        owners[scope.filename] = owner
        return owner
    }

    func owns(scope: TextExerciseDraftScope, owner: UUID) -> Bool {
        owners[scope.filename] == owner
    }

    func isSubmitting(scope: TextExerciseDraftScope) -> Bool {
        submissions[scope.filename] != nil
    }

    func beginSubmission(scope: TextExerciseDraftScope) -> UUID? {
        guard !isSubmitting(scope: scope) else { return nil }
        let request = UUID()
        submissions[scope.filename] = request
        return request
    }

    func endSubmission(scope: TextExerciseDraftScope, request: UUID) {
        guard submissions[scope.filename] == request else { return }
        submissions[scope.filename] = nil
    }

    init(directory: URL) {
        self.directory = directory
    }

    func load(scope: TextExerciseDraftScope) async throws -> TextExerciseDraft? {
        await tail?.value
        let file = directory.appendingPathComponent(scope.filename)
        return try await Task.detached {
            guard FileManager.default.fileExists(atPath: file.path) else { return nil }
            let draft = try JSONDecoder().decode(TextExerciseDraft.self, from: Data(contentsOf: file))
            guard draft.scope == scope else { throw TextExerciseEditingError.invalidResponse }
            return draft
        }.value
    }

    func save(_ draft: TextExerciseDraft) -> Task<Swift.Result<Void, Error>, Never> {
        let preceding = tail
        let directory = directory
        let task = Task.detached { () -> Swift.Result<Void, Error> in
            await preceding?.value
            do {
                try FileManager.default.createDirectory(at: directory, withIntermediateDirectories: true)
                var excludedDirectory = directory
                var values = URLResourceValues()
                values.isExcludedFromBackup = true
                try excludedDirectory.setResourceValues(values)
                let data = try JSONEncoder().encode(draft)
                try data.write(to: directory.appendingPathComponent(draft.scope.filename), options: [.atomic, .completeFileProtectionUnlessOpen])
                return .success(())
            } catch {
                return .failure(error)
            }
        }
        tail = Task { _ = await task.value }
        return task
    }
}
