import Foundation
import RxSwift
import Model
import Data

/**
 * Service that provides data about the users login status.
 */
public protocol AccountService {

    /**
     * The latest authentication data. Publisher emits a new element whenever the login status of the user changes.
     */
    var authenticationData: Observable<AuthenticationData> { get }

//    func login(username: String, password: String, rememberMe: Bool) async -> LoginResponse

    /**
     - Returns: If the user is currently logged in.
     */
    func isLoggedIn() -> Bool

    /**
     * Deletes the JWT.
     */
    func logout()
}

/**
 * Can either be [LoggedIn] or [NotLoggedIn].
 */
public enum AuthenticationData {
    case NotLoggedIn
    case LoggedIn(authToken: String, account: DataState<Account>)
}

public struct LoginResponse {
    public let isSuccessful: Bool
}
