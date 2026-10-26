import Foundation

enum TrainingCopy {
    static func text(_ key: String) -> String { Bundle.module.localizedString(forKey: key, value: nil, table: "Training") }
    static func count(_ count: Int) -> String { String(format: text("answered.count"), count) }
}
