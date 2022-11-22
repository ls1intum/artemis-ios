import Foundation

public protocol BaseAttachment: Decodable {

    static var type: String { get }

    var id: Int? { get }
    var name: String? { get }
    var visibleToStudents: Bool? { get }
}

public enum Attachment: Decodable {
    fileprivate enum Keys: String, CodingKey {
        case type = "attachmentType"
    }

    case File(attachment: FileAttachment)
    case Unknown(attachment: UnknownAttachment)

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let type = try container.decode(String.self, forKey: Keys.type)
        switch type {
        case FileAttachment.type: self = .File(attachment: try FileAttachment(from: decoder))
        default: self = .Unknown(attachment: try UnknownAttachment(from: decoder))
        }
    }
}