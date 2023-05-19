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

@MainActor
class RootViewModel: ObservableObject {

    @Published var isLoading = true

    @Published var isLoggedIn = false
    @Published var didSetupNotifications = false

    private var cancellables: Set<AnyCancellable> = Set()

    init() {
        UserSession.shared.objectWillChange.sink {
            DispatchQueue.main.async { [weak self] in
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
    }
}
