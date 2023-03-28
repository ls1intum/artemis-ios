//
//  PushNotificationSettingsView.swift
//  
//
//  Created by Sven Andabaka on 28.03.23.
//

import SwiftUI
import DesignLibrary

public struct PushNotificationSettingsView: View {

    @StateObject private var viewModel = PushNotificationSettingsViewModel()

    public init() { }

    public var body: some View {
        DataStateView(data: $viewModel.pushNotificationSettings,
                      retryHandler: { await viewModel.getNotificationSettings() }) { notificationSettings in
            List(notificationSettings, id: \.settingId) { setting in
                Text(setting.settingId.rawValue)
            }
        }.task {
            await viewModel.getNotificationSettings()
        }
    }
}
