import Foundation

public protocol BaseAttachment: Codable {

    static var type: String { get }

    var id: Int? { get }
    var name: String? { get }
    var visibleToStudents: Bool? { get }
}

public enum Attachment: Codable {
    fileprivate enum Keys: String, CodingKey {
        case type = "attachmentType"
    }

    case file(attachment: FileAttachment)
    case unknown(attachment: UnknownAttachment)

    public init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: Keys.self)
        let type = try container.decode(String.self, forKey: Keys.type)
        switch type {
        case FileAttachment.type: self = .file(attachment: try FileAttachment(from: decoder))
        default: self = .unknown(attachment: try UnknownAttachment(from: decoder))
        }
    }
}
