import SwiftUI
import Navigation

@main
struct ArtemisApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var navigationController = NavigationController(path: NavigationPath())

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(navigationController)
        }
    }
}
