import SwiftUI
import Navigation

@main
struct ArtemisApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @StateObject private var navigationController = NavigationController()

    var body: some Scene {
        WindowGroup {
            RootView()
                .environmentObject(navigationController)
                .onOpenURL { url in
                    DeeplinkHandler.shared.handle(url: url)
                }
        }
    }
}
