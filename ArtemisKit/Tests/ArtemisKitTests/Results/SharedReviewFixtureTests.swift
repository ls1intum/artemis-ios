import XCTest
@testable import CourseView

final class SharedReviewFixtureTests: XCTestCase {
    private func fixture() throws -> [String: Any] {
        #if SWIFT_PACKAGE
        let bundle = Bundle.module
        #else
        let bundle = Bundle(for: Self.self)
        #endif
        let url = try XCTUnwrap(bundle.url(forResource: "native-result-fixtures", withExtension: "json", subdirectory: "Fixtures") ??
                                bundle.url(forResource: "native-result-fixtures", withExtension: "json"))
        return try XCTUnwrap(JSONSerialization.jsonObject(with: Data(contentsOf: url)) as? [String: Any])
    }
    func testSharedScoreCasesPreserveUnknownZeroBonusAndPrecision() throws {
        for item in try XCTUnwrap(fixture()["scoreCases"] as? [[String: Any]]) {
            let actual = ReviewScore.points(score: item["score"] as? Double, maximum: item["maxPoints"] as? Double, precision: item["accuracyOfScores"] as? Int ?? 1)
            XCTAssertEqual(actual, item["expectedPoints"] as? Double, item["name"] as? String ?? "")
        }
    }
    func testSharedPublicFeedbackNeverRetainsPrivateGradingConfiguration() throws {
        for item in try XCTUnwrap(fixture()["feedbackCases"] as? [[String: Any]]) {
            let data = try JSONSerialization.data(withJSONObject: XCTUnwrap(item["input"]))
            let feedback = try JSONDecoder().decode(StudentFeedback.self, from: data)
            for message in item["expectedPublicText"] as? [String] ?? [] { XCTAssertTrue(feedback.message.contains(message)) }
            for forbidden in item["forbiddenText"] as? [String] ?? [] { XCTAssertFalse(feedback.message.contains(forbidden)) }
            if let expectedID = item["expectedId"] as? Int64 { XCTAssertEqual(feedback.id, expectedID) }
        }
    }
    func testSharedUnicodeAnchorsAndMalformedAnchors() throws {
        for item in try XCTUnwrap(fixture()["textCases"] as? [[String: Any]]) {
            let text = try XCTUnwrap(item["text"] as? String)
            let blocks = try JSONDecoder().decode([ReviewTextAnchor].self, from: JSONSerialization.data(withJSONObject: XCTUnwrap(item["blocks"])))
            let feedback = try XCTUnwrap(item["feedback"] as? [String: Any])
            let range = ReviewTextAnchor.resolve(reference: feedback["reference"] as? String, blocks: blocks, text: text)
            if let expected = item["expectedUTF16Range"] as? [Int] {
                XCTAssertEqual(range, NSRange(location: expected[0], length: expected[1] - expected[0]))
            } else { XCTAssertNil(range) }
        }
    }
}
