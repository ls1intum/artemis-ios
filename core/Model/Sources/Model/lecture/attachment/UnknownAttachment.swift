import Foundation

public struct UnknownAttachment: BaseAttachment {
    public var id: Int? = nil
    public var name: String? = nil
    public var visibleToStudents: Bool? = nil

    public static var type: String {
        "unknown"
    }
}
