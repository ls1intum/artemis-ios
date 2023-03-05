import Foundation

public struct FileAttachment: BaseAttachment {

    public var id: Int?
    public var name: String?
    public var visibleToStudents: Bool?
    public var link: String?
    public var version: Int?
    public var uploadDate: Date?
    //    public var releaseDate: Date?

    public static var type: String {
        "FILE"
    }
}
