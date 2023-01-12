import Foundation
import Combine
import Alamofire
import RxCombine
import RxSwift
import Model
import Data
import Device
import UserStore

class AccountServiceImpl: AccountService {

    let serverConfigurationService: ServerConfigurationService
    let networkStatusProvider: NetworkStatusProvider
    let jsonProvider: JsonProvider
    let serverDataService: ServerDataService

    /**
     * Only set if the user logged in without remember me.
     */
    private let inMemoryJWT: BehaviorSubject<String?>

    let authenticationData: Observable<AuthenticationData>

    init(
            serverConfigurationService: ServerConfigurationService,
            jsonProvider: JsonProvider,
            networkStatusProvider: NetworkStatusProvider,
            serverDataService: ServerDataService
    ) {
        self.serverConfigurationService = serverConfigurationService
        self.jsonProvider = jsonProvider
        self.networkStatusProvider = networkStatusProvider
        self.serverDataService = serverDataService

        inMemoryJWT = BehaviorSubject(value: nil)

        let loginJwtPublisher: Observable<String?> = UserDefaults
                .standard
                .publisher(for: \.loginJwt)
                .asObservable()

        authenticationData =
                Observable
                        .combineLatest(loginJwtPublisher, inMemoryJWT) { storedJWT, inMemoryJWT in
                            inMemoryJWT ?? storedJWT
                        }
                        .transformLatest { sub, key in
                            //TODO: Verify if the key has expired, etc
                            if let setKey = key {
                                try! await sub.sendAll(
                                        publisher: serverConfigurationService
                                                .serverUrl
                                                .transformLatest { sub2, serverUrl in
                                                    try! await sub2.sendAll(
                                                            publisher: serverDataService.getAccountData(serverUrl: serverUrl, authToken: setKey)
                                                    )
                                                }
                                                .map { account in
                                                    AuthenticationData.LoggedIn(authToken: setKey, account: account)
                                                }
                                )
                            } else {
                                sub.onNext(AuthenticationData.NotLoggedIn)
                            }
                        }
                        .share(replay: 1)
    }

//    func login(username: String, password: String, rememberMe: Bool) async -> LoginResponse {
//        let serverUrl = (try? await serverConfigurationService.serverUrl.first().value) ?? ""
//        let loginResponse = await LoginService().login(username: username, password: password, rememberMe: rememberMe, serverUrl: serverUrl)
//        switch loginResponse {
//        case .response(data: let data):
//            //either store the token permanently, or just cache it in memory.
//            if (rememberMe) {
//                UserDefaults.standard.loginJwt = data.idToken
//            } else {
//                inMemoryJWT.onNext(data.idToken)
//            }
//
//            return LoginResponse(isSuccessful: true)
//        case .failure: return LoginResponse(isSuccessful: false)
//        }
//    }

    func isLoggedIn() -> Bool {
        (try? inMemoryJWT.value() ?? nil) != nil || UserDefaults.standard.loginJwt != nil
    }

    func logout() {
        UserSession.shared.saveBearerToken(token: nil, shouldRemember: false)
    }
}

extension UserDefaults {
    @objc var loginJwt: String? {
        get {
            string(forKey: "jwt")
        }
        set {
            set(newValue, forKey: "jwt")
        }
    }
}

private struct LoginBody: Codable {
    let username: String
    let password: String
    let rememberMe: Bool
}

private struct LoginResponseBody: Codable {
    let id_token: String
}
