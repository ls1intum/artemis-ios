import SwiftUI
import Navigation

@main
struct iOSApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var navigationController = NavigationController(path: NavigationPath())

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(navigationController)
        }
    }
}
