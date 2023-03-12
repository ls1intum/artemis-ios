import Foundation
import SwiftUI
import Common
import DesignLibrary

public struct LoginView: View {
    enum FocusField {
        case username, password
    }

    @StateObject private var viewModel = LoginViewModel()

    @State private var showInstituionSelection = false
    @FocusState private var focusedField: FocusField?

    public init() { }

    public var body: some View {
        GeometryReader { geometry in
            ScrollView {
                VStack(spacing: .xl) {

                    header
                        .padding(.top, .xl)

                    Text(R.string.localizable.login_please_sign_in_account(viewModel.instituiton.shortName))
                        .font(.customBody)
                        .multilineTextAlignment(.center)
                        .padding(.top, -.l)

                    VStack(spacing: .l) {
                        VStack(alignment: .leading, spacing: .xxs) {
                            Text(R.string.localizable.login_username_label())
                            TextField(R.string.localizable.login_your_username_label(), text: $viewModel.username)
                                .textContentType(.username)
                                .textInputAutocapitalization(.never)
                                .textFieldStyle(ArtemisTextField())
                                .border(Color.Artemis.loginTextFieldBorderColor, width: 1)
                                .focused($focusedField, equals: .username)
                                .submitLabel(.next)
                            if viewModel.showUsernameWarning {
                                Text(String(R.string.localizable.login_username_validation_tum_info_label()))
                                    .foregroundColor(Color.Artemis.infoLabel)
                                    .font(.callout)
                            }
                        }
                        VStack(alignment: .leading, spacing: .xxs) {
                            Text(R.string.localizable.login_password_label)
                            SecureField(R.string.localizable.login_your_password_label(), text: $viewModel.password)
                                .textContentType(.password)
                                .textInputAutocapitalization(.never)
                                .textFieldStyle(ArtemisTextField())
                                .border(Color.Artemis.loginTextFieldBorderColor, width: 1)
                                .focused($focusedField, equals: .password)
                                .submitLabel(.continue)
                        }
                        Toggle(R.string.localizable.login_remember_me_label(), isOn: $viewModel.rememberMe)
                            .toggleStyle(.switch)
                            .tint(Color.Artemis.toggleColor)
                    }
                        .frame(maxWidth: 520)
                        .onSubmit {
                            if focusedField == .username {
                                focusedField = .password
                            } else if focusedField == .password {
                                focusedField = nil
                                viewModel.isLoading = true
                                Task {
                                    await viewModel.login()
                                }
                            }
                        }
                        .toolbar {
                            ToolbarItemGroup(placement: .keyboard) {
                                Spacer()

                                Button(R.string.localizable.done()) {
                                    focusedField = nil
                                }
                            }
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

                    VStack(spacing: .l) {
                        if let url = viewModel.externalPasswordResetLink.value {
                            Button(R.string.localizable.login_forgot_password_label()) {
                                UIApplication.shared.open(url)
                            }
                        }

                        Button(R.string.localizable.account_change_artemis_instance_label()) {
                            showInstituionSelection = true
                        }
                        .sheet(isPresented: $showInstituionSelection) {
                            InstitutionSelectionView(institution: $viewModel.instituiton,
                                                     handleProfileInfoCompletion: viewModel.handleProfileInfoReceived)
                        }
                    }
                        .padding(.bottom, .m)
                }
                .padding(.horizontal, .l)
                .frame(minHeight: geometry.size.height)
                .frame(maxWidth: .infinity)
            }
            .scrollDisabled(!viewModel.captchaRequired && focusedField != .password)
        }
            .loadingIndicator(isLoading: $viewModel.isLoading)
            .background(Color.Artemis.loginBackgroundColor)
            .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
            .alert(isPresented: $viewModel.loginExpired) {
                Alert(title: Text(R.string.localizable.account_session_expired_error()),
                      dismissButton: .default(Text(R.string.localizable.ok()),
                                              action: { viewModel.resetLoginExpired() }))
            }
            .task {
                await viewModel.getProfileInfo()
            }
    }

    var header: some View {
        VStack(spacing: .l) {
            Text(R.string.localizable.account_screen_title())
                .font(.largeTitle)
                .bold()
                .multilineTextAlignment(.center)

            Text(R.string.localizable.account_screen_subtitle())
                .font(.customBody)
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
