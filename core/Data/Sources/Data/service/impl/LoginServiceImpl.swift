import Foundation
import Common

class LoginServiceImpl: LoginService {

    private let jsonProvider: JsonProvider

    init(jsonProvider: JsonProvider) {
        self.jsonProvider = jsonProvider
    }

    func login(username: String, password: String, rememberMe: Bool, serverUrl: String) async -> NetworkResponse<LoginResponse> {
        await performNetworkCall {
            var components = URLComponents(string: serverUrl)!
            components.path += "api/authenticate"

            var request = URLRequest(url: components.url!)
            request.httpMethod = "POST"
            request.contentTypeJson()
            request.httpBody = try LoginBody(username: username, password: password, rememberMe: rememberMe).asData(encoder: jsonProvider.encoder)

            let (data, _) = try await URLSession.shared.data(for: request)
            return try data.parseJson(LoginResponse.self, jsonProvider.decoder)
        }
    }
}

private struct LoginBody: Encodable {
    let username: String
    let password: String
    let rememberMe: Bool
}
