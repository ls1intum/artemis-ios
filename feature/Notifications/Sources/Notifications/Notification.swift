import Foundation

struct Notification: Codable {
    var id: Int
    let title: String
    let text: String?
    let notificationDate: Date
    let target: String
}

extension Notification: Identifiable { }
