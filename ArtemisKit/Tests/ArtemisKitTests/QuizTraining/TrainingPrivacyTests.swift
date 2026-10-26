import XCTest
@testable import Quiz

@MainActor
final class TrainingPrivacyTests: XCTestCase {
    func testInitialOnboardingSurvivesOverviewReadInitialization() async throws {
        let service = TrainingOverviewStub(settings: nil)
        let model = TrainingOverview(transport: service)
        await model.load()
        XCTAssertTrue(model.needsPrivacyChoice)
        await model.load()
        XCTAssertTrue(model.needsPrivacyChoice)
        XCTAssertEqual(service.writes, [])
        await model.setVisibility(false)
        XCTAssertFalse(model.needsPrivacyChoice)
        XCTAssertEqual(service.writes, [false])
    }
    func testPrivateAndPublicSettingsRemainUnchangedOnReads() async {
        for visibility in [false, true] {
            let service = TrainingOverviewStub(settings: visibility)
            let model = TrainingOverview(transport: service)
            await model.load()
            XCTAssertFalse(model.needsPrivacyChoice)
            XCTAssertEqual(model.visibility, visibility)
            XCTAssertEqual(service.writes, [])
        }
    }
}

final class TrainingOverviewStub: TrainingOverviewServing {
    var isCurrent = true
    var settings: Bool?
    var writes: [Bool] = []
    private var reads = 0
    init(settings: Bool?) { self.settings = settings }
    func overview() async throws -> TrainingLeaderboard {
        reads += 1
        return .init(hasUserSetSettings: reads > 1 || settings != nil)
    }
    func visibility() async throws -> Bool? { settings }
    func setVisibility(_ visible: Bool) async throws { writes.append(visible); settings = visible }
}
