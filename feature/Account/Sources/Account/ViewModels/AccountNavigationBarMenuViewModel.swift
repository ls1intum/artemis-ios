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
                UserSession.shared.saveNotificationDeviceConfiguration(token: notificationDeviceConfiguration.apnsDeviceToken,
                                                                       encryptionKey: nil,
                                                                       skippedNotifications: notificationDeviceConfiguration.skippedNotifications)
                APIClient().perfomLogout()
            case .failure(let error):
                if let error = error as? APIClientError {
                    switch error {
                    case .httpURLResponseError(let statusCode, _):
                        if statusCode == .methodNotAllowed {
                            // ignore network error and login anyway
                            // TODO: schedule task to retry above functionality
                            APIClient().perfomLogout()
                        }
                    case .networkError:
                        // ignore network error and login anyway
                        // TODO: schedule task to retry above functionality
                        APIClient().perfomLogout()
                    default:
                        // do nothing
                        break
                    }                }
                log.error(error.localizedDescription)
                self.error = UserFacingError(title: error.localizedDescription)
            default:
                return
            }
        }
    }
}
