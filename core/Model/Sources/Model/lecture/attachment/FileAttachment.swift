import Foundation

public struct FileAttachment : BaseAttachment {

    public var id: Int? = nil
    public var name: String? = nil
    public var visibleToStudents: Bool? = nil
    public var link: String? = nil
    public var version: Int? = nil
    public var uploadDate: Date? = nil
    public var releaseDate: Date? = nil

    public static var type: String {
        "FILE"
    }
}
