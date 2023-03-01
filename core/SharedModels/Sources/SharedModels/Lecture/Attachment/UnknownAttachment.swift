import Foundation

public struct UnknownAttachment: BaseAttachment {
    public var id: Int?
    public var name: String?
    public var visibleToStudents: Bool?

    public static var type: String {
        "unknown"
    }
}
