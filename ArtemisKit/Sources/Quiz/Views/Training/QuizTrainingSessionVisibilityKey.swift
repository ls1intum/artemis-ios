import SwiftUI

/// Lets the containing course suppress its additional iPad tab controls without replacing the session subtree.
public struct QuizTrainingSessionVisibilityKey: PreferenceKey {
    public static let defaultValue = false
    public static func reduce(value: inout Bool, nextValue: () -> Bool) { value = value || nextValue() }
}
