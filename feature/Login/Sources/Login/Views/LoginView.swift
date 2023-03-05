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

            Text("Please sign in with your \(viewModel.instituiton.shortName) account.")
                .font(.title2)
                .multilineTextAlignment(.center)

            VStack(spacing: .m) {
                TextField(R.string.localizable.username(), text: $viewModel.username)
                    .textFieldStyle(ArtemisTextField())
                SecureField("Password", text: $viewModel.password)
                    .textFieldStyle(ArtemisTextField())
                Toggle("Automatic login", isOn: $viewModel.rememberMe)
                    .toggleStyle(.switch)
                    .tint(Color.Artemis.toggleColor)
            }

            Button("Login", action: {
                viewModel.isLoading = true
                Task {
                    await viewModel.login()
                }
            })
            .disabled(viewModel.username.isEmpty || viewModel.password.count < 8)
            .buttonStyle(ArtemisButton())

            Spacer()

            Button("Not your university?") {
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
            Alert(title: Text("Your session expired. Please login again!"),
                  dismissButton: .default(Text("OK"),
                                          action: { viewModel.resetLoginExpired() }))
        }
    }

    var header: some View {
        VStack(spacing: .l) {

            InstitutionLogo(institution: viewModel.instituiton)
                .frame(width: .extraLargeImage)
                .padding(.vertical, .xxl)

            Text("Welcome to Artemis!")
                .font(.largeTitle)
                .multilineTextAlignment(.center)

            Text("Interactive Learning with Individual Feedback")
                .font(.title2)
                .multilineTextAlignment(.center)
                .padding(.bottom, .xl)

            if viewModel.captchaRequired {
                DataStateView(data: $viewModel.externalUserManagementUrl, retryHandler: viewModel.getProfileInfo) { externalUserManagementURL in
                    DataStateView(data: $viewModel.externalUserManagementName, retryHandler: viewModel.getProfileInfo) { externalUserManagementName in
                        VStack {
                            Text("You have entered your password incorrectly too many times :-(")
                            Text(.init("Please go to [\(externalUserManagementName)](\(externalUserManagementURL.absoluteString)), sign in with your account and solve the [CAPTCHA](\(externalUserManagementURL.absoluteString)). After you have solved it, try to log in again here."))
                        }
                        .padding()
                        .border(.red)
                    }
                }
            }
        }
    }
}
