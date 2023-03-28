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

    @Published var pushNotificationSettings: DataState<[PushNotificationSetting]> = .loading

    func getNotificationSettings() async {
        pushNotificationSettings = await PushNotificationServiceFactory.shared.getNotificationSettings()
    }
    
}
