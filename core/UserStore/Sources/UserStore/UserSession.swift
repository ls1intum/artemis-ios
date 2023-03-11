//
//  File.swift
//
//
//  Created by Sven Andabaka on 09.01.23.
//

import Foundation

public class UserSession: ObservableObject {

    // Login Data
    @Published public private(set) var isLoggedIn = false
    @Published public private(set) var username: String?
    @Published public private(set) var password: String?
    @Published public private(set) var tokenExpired = false

    // Push Notifications
    @Published public private(set) var apnsDeviceToken: String?
    @Published public private(set) var notificationsEncryptionKey: String?

    // Institution Selection
    @Published public private(set) var institution: InstitutionIdentifier?

    public static let shared = UserSession()

    private init() {
        setupLoginData()
        setupNotificationData()
        setupInstitutionSelection()
    }

    private func setupInstitutionSelection() {
        if let institutionData = KeychainHelper.shared.read(service: "institution", account: "Artemis") {
            institution = InstitutionIdentifier(value: String(data: institutionData, encoding: .utf8))
        }
    }

    private func setupNotificationData() {
        if let apnsDeviceTokenData = KeychainHelper.shared.read(service: "apnsDeviceToken", account: "Artemis") {
            apnsDeviceToken = String(data: apnsDeviceTokenData, encoding: .utf8)
        }
        if let notificationsEncryptionKeyData = KeychainHelper.shared.read(service: "notificationsEncryptionKey", account: "Artemis") {
            notificationsEncryptionKey = String(data: notificationsEncryptionKeyData, encoding: .utf8)
        }
    }

    private func setupLoginData() {
        if let tokenData = KeychainHelper.shared.read(service: "isLoggedIn", account: "Artemis") {
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

    public func setUserLoggedIn(isLoggedIn: Bool) {
        self.isLoggedIn = isLoggedIn
        let isLoggedInData = Data(isLoggedIn.description.utf8)
        KeychainHelper.shared.save(isLoggedInData, service: "isLoggedIn", account: "Artemis")
    }

    public func saveUsername(username: String?) {
        self.username = username

        if let username {
            let usernameData = Data(username.description.utf8)
            KeychainHelper.shared.save(usernameData, service: "username", account: "Artemis")
        } else {
            KeychainHelper.shared.delete(service: "username", account: "Artemis")
        }
    }

    public func savePassword(password: String?) {
        self.password = password

        if let password {
            let passwordData = Data(password.description.utf8)
            KeychainHelper.shared.save(passwordData, service: "password", account: "Artemis")
        } else {
            KeychainHelper.shared.delete(service: "password", account: "Artemis")
        }
    }

    public func saveApnsDeviceToken(token: String?) {
        self.apnsDeviceToken = token

        if let token {
            let tokenData = Data(token.description.utf8)
            KeychainHelper.shared.save(tokenData, service: "apnsDeviceToken", account: "Artemis")
        } else {
            KeychainHelper.shared.delete(service: "apnsDeviceToken", account: "Artemis")
        }
    }

    public func saveNotificationsEncryptionKey(key: String?) {
        self.notificationsEncryptionKey = key

        if let key {
            let keyData = Data(key.description.utf8)
            KeychainHelper.shared.save(keyData, service: "notificationsEncryptionKey", account: "Artemis")
        } else {
            KeychainHelper.shared.delete(service: "notificationsEncryptionKey", account: "Artemis")
        }
    }

    public func saveInstitution(identifier: InstitutionIdentifier?) {
        self.institution = identifier

        if let identifier {
            let identifierData = Data(identifier.value.utf8)
            KeychainHelper.shared.save(identifierData, service: "institution", account: "Artemis")
        } else {
            KeychainHelper.shared.delete(service: "institution", account: "Artemis")
        }
    }
}
