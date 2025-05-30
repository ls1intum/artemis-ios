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
import ProfileInfo
import SwiftUI
import SharedServices
import UserStore

@MainActor
class RootViewModel: ObservableObject {

    @Published var isLoading = true
    @Published var isLoggedIn = false
    @Published var didSetupNotifications = false
    @Published var updateRequirement: UpdateRequirement = .upToDate

    private let userSession: UserSession
    private let accountService: AccountService

    private var cancellable: Set<AnyCancellable> = Set()

    init(
        userSession: UserSession = UserSessionFactory.shared,
        accountService: AccountService = AccountServiceFactory.shared
    ) {
        self.userSession = userSession
        self.accountService = accountService

        start()
    }

    /// Performs a request to the server to ensure the client is compatible and check which features are available.
    func checkFeaturesAndUpdates(forceCheck: Bool = false) async {
        guard userSession.isLoggedIn else {
            return
        }

        await FeatureList.shared.checkAvailability(forceCheck: forceCheck)

        let versionString = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
        let currentVersion = AppVersion(versionString)

        let supportedVersions = FeatureList.shared.compatibleVersions?.ios
        if let min = supportedVersions?.min, currentVersion < AppVersion(min) {
            updateRequirement = .requiresUpdate(current: versionString, min: min)
        } else if let min = supportedVersions?.recommended, currentVersion < AppVersion(min) {
            updateRequirement = .recommendsUpdate
        } else {
            updateRequirement = .upToDate
        }
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
                    Task {
                        await self.checkFeaturesAndUpdates(forceCheck: true)
                    }
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
                if isLoggedIn, let user = user.value {
                    userSession.user = user
                }
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

enum UpdateRequirement: Equatable {
    case upToDate
    case requiresUpdate(current: String, min: String)
    case recommendsUpdate
}

private struct AppVersion: Comparable {
    static func < (lhs: AppVersion, rhs: AppVersion) -> Bool {
        lhs.major < rhs.major ||
        lhs.major == rhs.major && lhs.minor < rhs.minor ||
        lhs.major == rhs.major && lhs.minor == rhs.minor && lhs.bugfix < rhs.bugfix
    }

    var major: Int = 0
    var minor: Int = 0
    var bugfix: Int = 0

    init(_ versionString: String) {
        let components = versionString.split(separator: ".")

        if components.count >= 1 {
            major = Int(components[0]) ?? 0
        }

        if components.count > 1 {
            minor = Int(components[1]) ?? 0
        }

        if components.count > 2 {
            bugfix = Int(components[2]) ?? 0
        }
    }
}
