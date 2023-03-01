import SwiftUI

public class NavigationController: ObservableObject {

    @Published public var path: NavigationPath

    public init(path: NavigationPath) {
        self.path = path
    }
}
