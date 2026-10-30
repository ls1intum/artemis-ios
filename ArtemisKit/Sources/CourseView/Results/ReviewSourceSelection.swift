import Foundation

@MainActor
@Observable
final class ReviewSourceSelection {
    struct Loaded {
        let reference: ReviewReference
        let commit: String
        let file: String
        let text: String
    }
    private(set) var loaded: Loaded?
    private(set) var loading = false
    private(set) var error: Error?
    private var requestID = UUID()

    func clear() { requestID = UUID(); loaded = nil; loading = false; error = nil }
    func load(file: String, reference: ReviewReference, commit: String, reader: any ReviewReading) async {
        let request = UUID(); requestID = request
        loaded = nil; error = nil; loading = true
        defer { if requestID == request { loading = false } }
        do {
            let data = try await reader.data(ReviewSourcePath.file(reference: reference, commit: commit, name: file))
            guard requestID == request, reader.isCurrent, !Task.isCancelled else { return }
            guard let text = String(bytes: data, encoding: .utf8), !data.contains(0) else { throw ReviewError.identity }
            loaded = Loaded(reference: reference, commit: commit, file: file, text: text)
        } catch {
            guard requestID == request else { return }
            self.error = error
        }
    }
    func highlight(for location: ReviewCodeLocation?) -> ReviewCodeLocation? {
        guard let loaded, let location, loaded.file == location.file else { return nil }
        return location
    }
}
