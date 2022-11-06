import Foundation

struct FileAttachment : BaseAttachment {

    var id: Int? = nil
    var name: String? = nil
    var visibleToStudents: Bool? = nil
    var link: String? = nil
    var version: Int? = nil
    var uploadDate: Date? = nil
    var releaseDate: Date? = nil

    public static var type: String {
        "FILE"
    }
}
