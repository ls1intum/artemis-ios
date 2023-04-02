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

    @Environment(\.dismiss) var dismiss

    private let shouldCloseOnSkip: Bool

    public init(shouldCloseOnSkip: Bool = false) {
        self.shouldCloseOnSkip = shouldCloseOnSkip
    }

    public var body: some View {
        VStack(spacing: .l) {
            Image("notifications", bundle: .module)
                .resizable()
                .scaledToFit()
                .frame(width: UIScreen.main.bounds.size.width * 0.8)
            Text(R.string.localizable.push_notification_settings_receive_label())
                .bold()
            Text(R.string.localizable.push_notification_settings_receive_information())
                .font(.caption)
                .padding(.l)
            Button("Register") {
                viewModel.isLoading = true
                Task {
                    await viewModel.register()
                }
            }
                .buttonStyle(ArtemisButton())
            Button("Skip") {
                viewModel.skip()
                if shouldCloseOnSkip {
                    dismiss()
                }
            }
                .buttonStyle(ArtemisButton(priority: .secondary))
        }
            .loadingIndicator(isLoading: $viewModel.isLoading)
            .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
            .padding(.l)
    }
}
