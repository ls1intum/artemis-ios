import Foundation
import Combine
import Alamofire
import RxCombine
import RxSwift
import Model

class AccountServiceImpl: AccountService {

    let serverCommunicationProvider: ServerCommunicationProvider
    let networkStatusProvider: NetworkStatusProvider
    let jsonProvider: JsonProvider

    /**
     * Only set if the user logged in without remember me.
     */
    private let inMemoryJWT: BehaviorSubject<String?>

    let authenticationData: Observable<AuthenticationData>

    init(serverCommunicationProvider: ServerCommunicationProvider, jsonProvider: JsonProvider, networkStatusProvider: NetworkStatusProvider) {
        self.serverCommunicationProvider = serverCommunicationProvider
        self.jsonProvider = jsonProvider
        self.networkStatusProvider = networkStatusProvider

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
                                        publisher: serverCommunicationProvider
                                                .serverUrl
                                                .transformLatest { sub2, serverUrl in
                                                    try! await sub2.sendAll(
                                                            publisher: retryOnInternet(connectivity: networkStatusProvider.currentNetworkStatus) {
                                                                await AccountServiceImpl.getAccountData(bearer: setKey, serverUrl: serverUrl, jsonProvider: jsonProvider)
                                                            }
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

    func login(username: String, password: String, rememberMe: Bool) async -> LoginResponse {
        let serverUrl = (try? await serverCommunicationProvider.serverUrl.first().value) ?? ""

        let body = LoginBody(username: username, password: password, rememberMe: rememberMe)

        let headers: Alamofire.HTTPHeaders = [
            .accept(ContentTypes.Application.Json),
            .contentType(ContentTypes.Application.Json),
            .defaultUserAgent
        ]

        let loginResponse = await performNetworkCall {
            try await AF.request(
                            serverUrl + "api/authenticate",
                            method: .post,
                            parameters: body,
                            encoder: JSONParameterEncoder.json(encoder: jsonProvider.encoder),
                            headers: headers
                    )
                    .serializingDecodable(LoginResponseBody.self, decoder: jsonProvider.decoder)
                    .value
        }

        switch loginResponse {
        case .response(data: let data):
            //either store the token permanently, or just cache it in memory.
            if (rememberMe) {
                UserDefaults.standard.loginJwt = data.id_token
            } else {
                inMemoryJWT.onNext(data.id_token)
            }

            return LoginResponse(isSuccessful: true)
        case .failure(error: _):
            return LoginResponse(isSuccessful: false)
        }
    }

    func isLoggedIn() -> Bool {
        (try? inMemoryJWT.value() ?? nil) != nil || UserDefaults.standard.loginJwt != nil
    }

    func logout() {
        inMemoryJWT.onNext(nil)
        UserDefaults.standard.loginJwt = nil
    }

    private static func getAccountData(bearer: String, serverUrl: String, jsonProvider: JsonProvider) async -> NetworkResponse<Account> {
        let headers: HTTPHeaders = [
            .accept(ContentTypes.Application.Json),
            .defaultUserAgent,
            .authorization(bearerToken: bearer)
        ]

        return await performNetworkCall {
            try await AF.request(serverUrl + "api/account", headers: headers)
                    .serializingDecodable(Account.self)
                    .value
        }
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
