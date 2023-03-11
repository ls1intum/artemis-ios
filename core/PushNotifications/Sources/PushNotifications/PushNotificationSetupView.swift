//
//  PushNotificationSetupView.swift
//  
//
//  Created by Sven Andabaka on 11.03.23.
//

import SwiftUI
import DesignLibrary

public struct PushNotificationSetupView: View {

    @StateObject private var viewModel = PushNotificationSetupViewModel()

    public init() { }

    public var body: some View {
        VStack(spacing: .m) {
            Text(R.string.localizable.push_notification_settings_receive_label())
                .bold()
            Text(R.string.localizable.push_notification_settings_receive_information())
                .font(.caption)
                .padding(.l)
            Button("Register") {
                Task {
                    await viewModel.register()
                }
            }
                .buttonStyle(ArtemisButton())
            Button("Skip") {
                viewModel.skip()
            }
                .buttonStyle(ArtemisButton(priority: .secondary))
        }
    }
}
