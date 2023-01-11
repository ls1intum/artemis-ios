import Foundation

@MainActor class LoginViewModel: ObservableObject {

    func login(username: String, password: String, rememberMe: Bool) async -> Bool {
        await LoginServiceFactory.shared.login(username: username, password: password, rememberMe: rememberMe)
    }
}
