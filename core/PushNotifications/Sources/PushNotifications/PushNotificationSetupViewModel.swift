//
//  File.swift
//  
//
//  Created by Sven Andabaka on 11.03.23.
//

import Foundation
import Common
import UserStore
import UIKit
import Combine

@MainActor
class PushNotificationSetupViewModel: ObservableObject {

    @Published var isLoading = false
    @Published var error: UserFacingError? {
        didSet {
            showError = error != nil
            if showError {
                isLoading = false
            }
        }
    }
    @Published var showError = false

    private var cancellables: Set<AnyCancellable> = Set()

    init() {
        UserSession.shared.objectWillChange.sink {
            DispatchQueue.main.async { [weak self] in
                self?.updateFromUserSession()
            }
        }.store(in: &cancellables)

        updateFromUserSession()
    }

    private func updateFromUserSession() {
        error = UserSession.shared.notificationSetupError
    }

    func register() async {
        UserSession.shared.notificationSetupError = nil
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.sound, .badge, .alert])

            guard granted else { return }
            // 2. Attempt registration for remote notifications on the main thread
            UIApplication.shared.registerForRemoteNotifications()
        } catch {
            log.error("Error registering for remote notification", error.localizedDescription)
        }
    }

    func skip() {
        UserSession.shared.saveNotificationDeviceConfiguration(token: nil, encryptionKey: nil, skippedNotifications: true)
    }
}
