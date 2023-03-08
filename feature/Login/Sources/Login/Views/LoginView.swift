import Foundation
import SwiftUI
import Common
import DesignLibrary

public struct LoginView: View {
    @StateObject private var viewModel = LoginViewModel()

    @State private var showInstituionSelection = false

    public init() { }

    public var body: some View {
        VStack(spacing: .l) {

            header

            Text(R.string.localizable.login_please_sign_in_account(viewModel.instituiton.shortName))
                .font(.title2)
                .multilineTextAlignment(.center)

            VStack(spacing: .m) {
                TextField(R.string.localizable.login_username_label(), text: $viewModel.username)
                    .textFieldStyle(ArtemisTextField())
                SecureField(R.string.localizable.login_password_label(), text: $viewModel.password)
                    .textFieldStyle(ArtemisTextField())
                Toggle(R.string.localizable.login_remember_me_label(), isOn: $viewModel.rememberMe)
                    .toggleStyle(.switch)
                    .tint(Color.Artemis.toggleColor)
            }

            Button(R.string.localizable.login_perform_login_button_text()) {
                viewModel.isLoading = true
                Task {
                    await viewModel.login()
                }
            }
                .disabled(viewModel.username.isEmpty || viewModel.password.count < 8)
                .buttonStyle(ArtemisButton())

            Spacer()

            Button(R.string.localizable.account_change_artemis_instance_label()) {
                showInstituionSelection = true
            }
                .sheet(isPresented: $showInstituionSelection) {
                    InstitutionSelectionView(institution: $viewModel.instituiton)
                }
        }
            .padding(.horizontal, .l)
            .loadingIndicator(isLoading: $viewModel.isLoading)
            .background(Color.Artemis.loginBackgroundColor)
            .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
            .alert(isPresented: $viewModel.loginExpired) {
                Alert(title: Text(R.string.localizable.account_session_expired_error()),
                      dismissButton: .default(Text(R.string.localizable.ok()),
                                              action: { viewModel.resetLoginExpired() }))
            }
    }

    var header: some View {
        VStack(spacing: .l) {

            InstitutionLogo(institution: viewModel.instituiton)
                .frame(width: .extraLargeImage)
                .padding(.vertical, .xxl)

            Text(R.string.localizable.account_screen_title())
                .font(.largeTitle)
                .multilineTextAlignment(.center)

            Text(R.string.localizable.account_screen_subtitle())
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.bottom, .xl)

            if viewModel.captchaRequired {
                DataStateView(data: $viewModel.externalUserManagementUrl, retryHandler: viewModel.getProfileInfo) { externalUserManagementURL in
                    DataStateView(data: $viewModel.externalUserManagementName, retryHandler: viewModel.getProfileInfo) { externalUserManagementName in
                        VStack {
                            Text(R.string.localizable.account_captcha_title())
                            Text(.init(R.string.localizable.account_captcha_message(externalUserManagementName,
                                                                                    externalUserManagementURL.absoluteString,
                                                                                    externalUserManagementURL.absoluteString)))
                        }
                        .padding()
                        .border(.red)
                    }
                }
            }
        }
    }
}
