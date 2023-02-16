//
//  File.swift
//
//
//  Created by Sven Andabaka on 09.01.23.
//

import Foundation

public class UserSession: ObservableObject {
    @Published public private(set) var isLoggedIn = false
    @Published public private(set) var username: String?
    @Published public private(set) var password: String?
    @Published public private(set) var rememberMe = false

    @Published public private(set) var tokenExpired = false

    // push notifications
    @Published public var apnsDeviceToken: String?
    @Published public var notificationsEncryptionKey: String?

    public static let shared = UserSession()

    private init() {
        if let rememberData = KeychainHelper.shared.read(service: "shouldRemember", account: "Artemis") {
            rememberMe = String(data: rememberData, encoding: .utf8) == "true"
        }
        if rememberMe,
           let tokenData = KeychainHelper.shared.read(service: "isLoggedIn", account: "Artemis") {
            isLoggedIn = String(data: tokenData, encoding: .utf8) == "true"
        }

        if let username = KeychainHelper.shared.read(service: "username", account: "Artemis") {
            self.username = String(data: username, encoding: .utf8)
        }

        if let password = KeychainHelper.shared.read(service: "password", account: "Artemis") {
            self.password = String(data: password, encoding: .utf8)
        }
    }

    public func setTokenExpired(expired: Bool) {
        tokenExpired = expired
    }

    public func setUserLoggedIn(isLoggedIn: Bool, shouldRemember: Bool) {
        self.isLoggedIn = isLoggedIn
        self.rememberMe = shouldRemember
        let isLoggedInData = Data(isLoggedIn.description.utf8)
        let rememberData = Data(shouldRemember.description.utf8)
        KeychainHelper.shared.save(isLoggedInData, service: "isLoggedIn", account: "Artemis")
        KeychainHelper.shared.save(rememberData, service: "shouldRemember", account: "Artemis")
    }

    public func saveUsername(username: String?) {
        self.username = username

        if let username = username {
            let usernameData = Data(username.description.utf8)
            KeychainHelper.shared.save(usernameData, service: "username", account: "Artemis")
        } else {
            KeychainHelper.shared.delete(service: "username", account: "Artemis")
        }
    }

    public func savePassword(password: String?) {
        self.password = password

        if let password = password {
            let passwordData = Data(password.description.utf8)
            KeychainHelper.shared.save(passwordData, service: "password", account: "Artemis")
        } else {
            KeychainHelper.shared.delete(service: "password", account: "Artemis")
        }
    }
}
