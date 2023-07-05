//
//  RootViewModel.swift
//  Artemis
//
//  Created by Sven Andabaka on 12.01.23.
//  Copyright © 2023 orgName. All rights reserved.
//

import Foundation
import Combine
import UserStore
import SwiftUI
import SharedServices
import PushNotifications
import Common

@MainActor
class RootViewModel: ObservableObject {

    @Published var isLoading = true

    @Published var isLoggedIn = false
    @Published var didSetupNotifications = false

    private var cancellables: Set<AnyCancellable> = Set()

    init() {
        UserSession.shared.objectWillChange.sink {
            DispatchQueue.main.async { [weak self] in
                if !(self?.isLoggedIn ?? false) && UserSession.shared.isLoggedIn {
                    self?.updateDeviceToken()
                }
                self?.isLoggedIn = UserSession.shared.isLoggedIn
                self?.didSetupNotifications = UserSession.shared.getCurrentNotificationDeviceConfiguration() != nil
            }
        }.store(in: &cancellables)

        Task(priority: .high) {
            let user = await AccountServiceFactory.shared.getAccount()

            switch user {
            case .loading, .failure:
                UserSession.shared.setTokenExpired(expired: false)
            case .done:
                isLoggedIn = UserSession.shared.isLoggedIn
                didSetupNotifications = UserSession.shared.getCurrentNotificationDeviceConfiguration() != nil
            }
            isLoading = false
        }

        updateDeviceToken()
    }

    private func updateDeviceToken() {
        if let notificationConfig = UserSession.shared.getCurrentNotificationDeviceConfiguration(),
           !notificationConfig.skippedNotifications {
            UserSession.shared.notificationSetupError = nil
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
