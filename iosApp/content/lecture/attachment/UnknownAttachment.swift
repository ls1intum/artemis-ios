import Foundation

struct UnknownAttachment: BaseAttachment {
    var id: Int? = nil
    var name: String? = nil
    var visibleToStudents: Bool? = nil

    public static var type: String {
        "unknown"
    }
}
