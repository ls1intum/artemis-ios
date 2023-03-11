//
//  File.swift
//
//
//  Created by Sven Andabaka on 10.02.23.
//

import Foundation
import Common
import APIClient
import SharedModels
import UserStore
import PushNotifications

@MainActor
class AccountNavigationBarMenuViewModel: ObservableObject {
    @Published var account: DataState<Account> = .loading
    @Published var error: UserFacingError?
    @Published var isLoading = false

    init() {
        Task {
            await getAccount()
        }
    }

    func getAccount() async {
        account = await AccountServiceFactory.shared.getAccount()
    }

    func logout() {
        isLoading = true
        Task {
            let result = await PushNotificationServiceFactory.shared.unregister()
            isLoading = false

            switch result {
            case .success:
                guard let notificationDeviceConfiguration = UserSession.shared.getCurrentNotificationDeviceConfiguration() else { return }
                UserSession.shared.saveNotificationDeviceConfiguration(token: nil, encryptionKey: nil, skippedNotifications: notificationDeviceConfiguration.skippedNotifications)
                APIClient().perfomLogout()
            case .failure(let error):
                log.error(error.localizedDescription)
                self.error = UserFacingError(title: error.localizedDescription)
            default:
                return
            }
        }
    }
}
