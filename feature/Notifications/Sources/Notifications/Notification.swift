import Foundation
import SharedModels

struct Notification: Codable {
    var id: Int
    let title: String
    let text: String?
    let notificationDate: Date
    let target: String
    let author: User?
}

extension Notification: Identifiable { }
