import Foundation

public protocol LoginService {

    /**
     * Perform a login request to the server.
     */
    func login(username: String, password: String, rememberMe: Bool, serverUrl: String) async -> NetworkResponse<LoginResponse>
}

public struct LoginResponse: Decodable {
    public let idToken: String

    enum CodingKeys: String, CodingKey {
        case idToken = "id_token"
    }
}