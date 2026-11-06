import Foundation
import SwiftUI

struct CourseScoreMetadata: Decodable {
    let id: Int
    let accuracyOfScores: Int?
    static func load(courseID: Int, reader: any ReviewReading) async throws -> Int {
        let metadata = try await reader.read(Self.self, path: "/api/course/courses/\(courseID)/for-overview")
        guard reader.isCurrent, metadata.id == courseID else { throw ReviewError.sessionChanged }
        return min(10, max(0, metadata.accuracyOfScores ?? 1))
    }
}
private struct ResultScorePrecisionKey: EnvironmentKey { static let defaultValue = 1 }
extension EnvironmentValues {
    var resultScorePrecision: Int {
        get { self[ResultScorePrecisionKey.self] }
        set { self[ResultScorePrecisionKey.self] = newValue }
    }
}
