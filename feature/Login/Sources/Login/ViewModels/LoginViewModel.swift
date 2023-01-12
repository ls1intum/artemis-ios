import Foundation
import APIClient

@MainActor class LoginViewModel: ObservableObject {

    func login(username: String, password: String, rememberMe: Bool) async -> NetworkResponse {
        await LoginServiceFactory.shared.login(username: username, password: password, rememberMe: rememberMe)
    }
}
