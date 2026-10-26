import Foundation

struct TrainingVisibility: Codable { let showInLeaderboard: Bool? }
struct TrainingLeaderboard: Decodable {
    var leaderboardEntries: [TrainingLeaderboardEntry]?
    var hasUserSetSettings: Bool?
    var currentUserEntry: TrainingLeaderboardEntry?
    var currentTime: Date?
}
struct TrainingLeaderboardEntry: Decodable {
    var rank: Int?
    var selectedLeague: Int?
    var userId: Int64?
    var userName: String?
    var score: Int?
    var answeredCorrectly: Int?
    var answeredWrong: Int?
    var totalQuestions: Int?
    var dueDate: Date?
    var streak: Int?
}
protocol TrainingOverviewServing {
    var isCurrent: Bool { get }
    func overview() async throws -> TrainingLeaderboard
    func visibility() async throws -> Bool?
    func setVisibility(_ visible: Bool) async throws
}

@Observable
@MainActor
final class TrainingOverview {
    let transport: TrainingOverviewServing
    private(set) var data: TrainingLeaderboard?
    private(set) var visibility: Bool?
    private(set) var initialHasSettings: Bool?
    private(set) var busy = false
    private(set) var failed = false
    private(set) var receivedAt: Date?
    private var lastRefreshedRevision = 0
    var currentRank: Int? { data?.currentUserEntry?.rank }
    var needsPrivacyChoice: Bool { initialHasSettings == false }
    init(transport: TrainingOverviewServing) { self.transport = transport }
    func load() async {
        guard !busy, transport.isCurrent else { return }
        busy = true; failed = false
        defer { busy = false }
        do {
            let response = try await transport.overview()
            guard transport.isCurrent else { clear(); return }
            if initialHasSettings == nil { initialHasSettings = response.hasUserSetSettings ?? false }
            data = response; receivedAt = .now
            visibility = try await transport.visibility()
            guard transport.isCurrent else { clear(); return }
        } catch { failed = true; if !transport.isCurrent { clear() } }
    }
    func refreshIfNeeded(after revision: Int) async {
        guard !busy, transport.isCurrent, revision != lastRefreshedRevision else { return }
        await load()
        if !failed, data != nil { lastRefreshedRevision = revision }
    }
    func setVisibility(_ visible: Bool) async {
        guard !busy, transport.isCurrent else { return }
        busy = true; failed = false
        defer { busy = false }
        do {
            try await transport.setVisibility(visible)
            guard transport.isCurrent else { clear(); return }
            visibility = visible; initialHasSettings = true
        } catch { failed = true; if !transport.isCurrent { clear() } }
    }
    func clear() { data = nil; visibility = nil; initialHasSettings = nil; receivedAt = nil }
}
