//
//  PushNotificationSettingsViewModel.swift
//  
//
//  Created by Sven Andabaka on 28.03.23.
//

import Foundation
import Common
import Combine
import UserStore

@MainActor
class PushNotificationSettingsViewModel: ObservableObject {

    @Published var didSetupNotifications = false

    @Published var isSaveDisabled = true
    @Published var pushNotificationSettingsRequest: DataState<Bool> = .loading

    @Published var pushNotificationSettings: [PushNotificationSettingId: PushNotificationSetting] = [:]

    private var cancellables: Set<AnyCancellable> = Set()

    init() {
        UserSession.shared.objectWillChange.sink {
            DispatchQueue.main.async { [weak self] in
                self?.didSetupNotifications = UserSession.shared.getCurrentNotificationDeviceConfiguration()?.notificationsEncryptionKey != nil
            }
        }.store(in: &cancellables)

        didSetupNotifications = UserSession.shared.getCurrentNotificationDeviceConfiguration()?.notificationsEncryptionKey != nil
    }

    func getNotificationSettings() async {
        pushNotificationSettingsRequest = .loading
        let result = await PushNotificationServiceFactory.shared.getNotificationSettings()

        _ = handleNetworkResponse(result: result)
    }

    func saveNotificationSettings() async -> Bool {
        pushNotificationSettingsRequest = .loading
        isSaveDisabled = true
        let notificationSettings = pushNotificationSettings.map { $0.value }
        let result = await PushNotificationServiceFactory.shared.saveNotificationSettings(notificationSettings)

        return handleNetworkResponse(result: result)
    }

    private func handleNetworkResponse(result: DataState<[PushNotificationSetting]>) -> Bool {
        switch result {
        case .loading:
            pushNotificationSettingsRequest = .loading
        case .failure(let error):
            pushNotificationSettingsRequest = .failure(error: error)
        case .done(let response):
            pushNotificationSettingsRequest = .done(response: true)
            self.pushNotificationSettings = Dictionary(uniqueKeysWithValues: response
                .filter {
                    $0.settingId != .other
                }
                .map {
                    ($0.settingId, $0)
                })
            return true
        }
        return false
    }
}
