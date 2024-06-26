import ArtemisKit
import SwiftUI

@main
struct ArtemisApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self)
    private var delegate: AppDelegate

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .onChange(of: scenePhase) { _, newPhase in
                    if newPhase == .background {
                        delegate.applicationDidEnterBackground(UIApplication.shared)
                    }
                }
        }
    }
}
