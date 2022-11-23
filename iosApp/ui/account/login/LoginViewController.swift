import Foundation
import UIKit
import Factory
import SwiftUI
import Datastore

@MainActor class LoginViewModel: ObservableObject {
    private var accountService: AccountService = Container.accountService()

    func login(username: String, password: String, rememberMe: Bool) async -> LoginResponse {
        await accountService.login(username: username, password: password, rememberMe: rememberMe)
    }
}
