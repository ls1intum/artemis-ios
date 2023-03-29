//
//  PushNotificationSettingsViewModel.swift
//  
//
//  Created by Sven Andabaka on 28.03.23.
//

import Foundation
import Common

@MainActor
class PushNotificationSettingsViewModel: ObservableObject {

    @Published var isSaveDisabled = true
    @Published var pushNotificationSettingsRequest: DataState<Bool> = .loading

    @Published var pushNotificationSettings: [PushNotificationSettingId: PushNotificationSetting] = [:]

    func getNotificationSettings() async {
        pushNotificationSettingsRequest = .loading
        let result = await PushNotificationServiceFactory.shared.getNotificationSettings()

        handleNetworkResponse(result: result)
    }

    func saveNotificationSettings() async {
        pushNotificationSettingsRequest = .loading
        let notificationSettings = pushNotificationSettings.map { $0.value }
        let result = await PushNotificationServiceFactory.shared.saveNotificationSettings(notificationSettings)

        handleNetworkResponse(result: result)
    }

    private func handleNetworkResponse(result: DataState<[PushNotificationSetting]>) {
        switch result {
        case .loading:
            pushNotificationSettingsRequest = .loading
        case .failure(let error):
            pushNotificationSettingsRequest = .failure(error: error)
        case .done(let response):
            pushNotificationSettingsRequest = .done(response: true)
            self.pushNotificationSettings = Dictionary(uniqueKeysWithValues: response.filter {
                    $0.settingId != .other
                }
                .map {
                    ($0.settingId, $0)
                })
        }
    }
}
