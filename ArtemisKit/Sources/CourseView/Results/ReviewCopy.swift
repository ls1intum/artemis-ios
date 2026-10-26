import Foundation

enum ReviewCopy {
    static func text(_ key: String) -> String { String(localized: String.LocalizationValue(key), table: "Review", bundle: .module) }
    static func group(_ group: StudentFeedback.Group) -> String {
        switch group {
        case .tests: text("review.tests")
        case .staticAnalysis: text("review.staticAnalysis")
        case .manual: text("review.comments")
        case .policy: text("review.policy")
        }
    }
    static func error(_ error: Error) -> String {
        switch error {
        case ReviewError.denied: text("review.denied")
        case ReviewError.sessionChanged: text("review.sessionChanged")
        case ReviewError.identity: text("review.identityError")
        case ReviewError.http(404): text("review.notFound")
        default: text("review.loadError")
        }
    }
}
