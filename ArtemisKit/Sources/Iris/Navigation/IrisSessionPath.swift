import Foundation
import Navigation
import SharedModels

public struct IrisSessionPath: Hashable {
    public let id: Int
    public let session: IrisSessionDTO?
    public let coursePath: CoursePath

    public init(id: Int, coursePath: CoursePath) {
        self.id = id
        self.session = nil
        self.coursePath = coursePath
    }

    public init(session: IrisSessionDTO, coursePath: CoursePath) {
        self.id = session.id
        self.session = session
        self.coursePath = coursePath
    }
}
