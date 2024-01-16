//
//  RootViewModel.swift
//  Artemis
//
//  Created by Sven Andabaka on 12.01.23.
//  Copyright © 2023 orgName. All rights reserved.
//

import Combine
import Common
import Foundation
import PushNotifications
import SwiftUI
import SharedServices
import UserStore

@Observable
@MainActor
class RootViewModel {

    var isLoading = true
    var isLoggedIn = false
    var didSetupNotifications = false

    private let userSession: UserSession
    private let accountService: AccountService

    @ObservationIgnored private var cancellable = Set<AnyCancellable>()

    init(
        userSession: UserSession = .shared,
        accountService: AccountService = AccountServiceFactory.shared
    ) {
        self.userSession = userSession
        self.accountService = accountService

        start()
    }
}

private extension RootViewModel {
    func start() {
        userSession.objectWillChange.sink {
            DispatchQueue.main.async { [weak self] in
                guard let self else {
                    return
                }

                if !self.isLoggedIn && self.userSession.isLoggedIn {
                    self.updateDeviceToken()
                }
                self.isLoggedIn = self.userSession.isLoggedIn
                self.didSetupNotifications = self.userSession.getCurrentNotificationDeviceConfiguration() != nil
            }
        }
        .store(in: &cancellable)

        Task(priority: .high) {
            let user = await accountService.getAccount()

            switch user {
            case .loading, .failure:
                userSession.setTokenExpired(expired: false)
            case .done:
                isLoggedIn = userSession.isLoggedIn
                didSetupNotifications = userSession.getCurrentNotificationDeviceConfiguration() != nil
            }
            isLoading = false
        }

        updateDeviceToken()
    }

    func updateDeviceToken() {
        if let notificationConfig = userSession.getCurrentNotificationDeviceConfiguration(),
           !notificationConfig.skippedNotifications {

            userSession.notificationSetupError = nil

            Task {
                do {
                    let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .badge, .alert])

                    guard granted else { return }
                    // 2. Attempt registration for remote notifications on the main thread
                    UIApplication.shared.registerForRemoteNotifications()
                } catch {
                    log.error("Error registering for remote notification", error.localizedDescription)
                }
            }
        }
    }
}
