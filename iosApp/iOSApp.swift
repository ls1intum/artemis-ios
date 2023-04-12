import SwiftUI
import Navigation

@main
struct ArtemisApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    @Environment(\.scenePhase) private var scenePhase

    var body: some Scene {
        WindowGroup {
            RootView()
                .onChange(of: scenePhase) { phase in
                    if phase == .background {
                        delegate.applicationDidEnterBackground(UIApplication.shared)
                    }
                }
        }
    }
}
