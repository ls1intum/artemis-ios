import ArtemisKit
import Navigation
import SwiftUI

@main
struct ArtemisApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    private var delegate: AppDelegate

    @Environment(\.scenePhase) private var scenePhase
    @StateObject private var navigationController = NavigationController()

    var body: some Scene {
        WindowGroup {
            RootView(navigationController: navigationController)
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .background {
                        delegate.applicationDidEnterBackground(UIApplication.shared)
                    }
                }
        }
    }
}
