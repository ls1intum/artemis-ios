import Foundation
import APIClient
import Common
import UserStore
import Combine
import ProfileInfo

@MainActor
class LoginViewModel: ObservableObject {
    @Published var username: String = ""
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

    @Published var instituiton: InstitutionIdentifier = .tum

    private var cancellables: Set<AnyCancellable> = Set()

    init() {
        UserSession.shared.objectWillChange.sink {
            DispatchQueue.main.async { [weak self] in
                self?.username = UserSession.shared.username ?? ""
                self?.password = UserSession.shared.password ?? ""
                self?.rememberMe = UserSession.shared.rememberMe
                self?.loginExpired = UserSession.shared.tokenExpired
                self?.instituiton = UserSession.shared.institution ?? .tum
            }
        }.store(in: &cancellables)

        username = UserSession.shared.username ?? ""
        password = UserSession.shared.password ?? ""
        rememberMe = UserSession.shared.rememberMe
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
            externalUserManagementUrl = .done(response: response.externalUserManagementURL)
            externalUserManagementName = .done(response: response.externalUserManagementName)
        }
    }
}
