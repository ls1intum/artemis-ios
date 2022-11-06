import Foundation

protocol Attachment: Decodable {
    var id: Int? { get }
    var name: String? { get }
    var visibleToStudents: Bool? { get }
}