import SwiftUI
import Navigation

@main
struct ArtemisApp: App {

    @UIApplicationDelegateAdaptor(AppDelegate.self) var delegate

    var body: some Scene {
        WindowGroup {
            RootView()
        }
    }
}
