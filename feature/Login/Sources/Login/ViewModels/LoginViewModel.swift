import Foundation
import APIClient
import Common
import UserStore
import Combine
import ProfileInfo
import SharedModels

@MainActor
class LoginViewModel: ObservableObject {
    @Published var username: String = "" {
        didSet {
            usernameValidation()
        }
    }
    @Published var password: String = ""
    @Published var rememberMe = true

    @Published var error: UserFacingError? {
        didSet {
            showError = error != nil
        }
    }
    @Published var showError = false
    @Published var isLoading = false

    @Published var loginExpired = false
    @Published var captchaRequired = false

    @Published var externalUserManagementUrl: DataState<URL> = .loading
    @Published var externalUserManagementName: DataState<String> = .loading
    @Published var externalPasswordResetLink: DataState<URL> = .loading
    @Published var usernamePattern: String?
    @Published var showUsernameWarning = false

    @Published var instituiton: InstitutionIdentifier = .tum

    private var cancellables: Set<AnyCancellable> = Set()

    init() {
        UserSession.shared.objectWillChange.sink {
            DispatchQueue.main.async { [weak self] in
                self?.username = UserSession.shared.username ?? ""
                self?.password = UserSession.shared.password ?? ""
                self?.loginExpired = UserSession.shared.tokenExpired
                self?.instituiton = UserSession.shared.institution ?? .tum
            }
        }.store(in: &cancellables)

        username = UserSession.shared.username ?? ""
        password = UserSession.shared.password ?? ""
        loginExpired = UserSession.shared.tokenExpired
        instituiton = UserSession.shared.institution ?? .tum
    }

    func login() async {
        let response = await LoginServiceFactory.shared.login(username: username, password: password, rememberMe: rememberMe)

        switch response {
        case .failure(let error):
            if let loginError = error as? LoginError {
                switch loginError {
                case .captchaRequired:
                    await getProfileInfo()
                    isLoading = false
                    captchaRequired = true
                    self.error = UserFacingError(title: R.string.localizable.account_captcha_alert_message())
                }
            } else if let apiClientError = error as? APIClientError {
                isLoading = false
                self.error = UserFacingError(error: apiClientError)
            } else {
                isLoading = false
                self.error = UserFacingError(title: error.localizedDescription)
            }
        default:
            isLoading = false
            return
        }
    }

    func resetLoginExpired() {
        UserSession.shared.setTokenExpired(expired: false)
    }

    func getProfileInfo() async {
        isLoading = true
        let response = await ProfileInfoServiceFactory.shared.getProfileInfo()
        isLoading = false

        switch response {
        case .loading:
            return
        case .failure(let error):
            self.error = error
        case .done(let response):
            handleProfileInfoReceived(profileInfo: response)
        }
    }

    func handleProfileInfoReceived(profileInfo: ProfileInfo?) {
        if let externalUserManagementURL = profileInfo?.externalUserManagementURL {
            self.externalUserManagementUrl = .done(response: externalUserManagementURL)
        } else {
            self.externalUserManagementUrl = .loading
        }
        if let externalUserManagementName = profileInfo?.externalUserManagementName {
            self.externalUserManagementName = .done(response: externalUserManagementName)
        } else {
            self.externalUserManagementUrl = .loading
        }
        if let allowedLdapUsernamePattern = profileInfo?.allowedLdapUsernamePattern,
           profileInfo?.accountName == "TUM" {
            self.usernamePattern = allowedLdapUsernamePattern
        } else {
            self.usernamePattern = nil
        }
        if let externalPasswordResetLinkMap = profileInfo?.externalPasswordResetLinkMap,
           let url = URL(string: externalPasswordResetLinkMap[Language.currentLanguage.rawValue] ?? "") {
            self.externalPasswordResetLink = .done(response: url)
        } else {
            self.externalPasswordResetLink = .loading
        }
        showUsernameWarning = false
        usernameValidation()
    }

    private func usernameValidation() {
        if username.count > 6,
           let usernamePattern,
           username.range(of: usernamePattern, options: .regularExpression) == nil {
            showUsernameWarning = true
        }
    }
}
