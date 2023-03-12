//
//  File.swift
//
//
//  Created by Sven Andabaka on 09.01.23.
//

import Foundation
import APIClient
import UserStore
import Common
import PushNotifications

class LoginServiceImpl: LoginService {
    private let client = APIClient()

    struct LoginUser: APIRequest {
        typealias Response = RawResponse

        var username: String
        var password: String
        var rememberMe: Bool

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/authenticate"
        }
    }

    func login(username: String, password: String, rememberMe: Bool) async -> NetworkResponse {
        if !rememberMe {
            UserSession.shared.saveUsername(username: nil)
            UserSession.shared.savePassword(password: nil)
        }

        let result = await client.sendRequest(LoginUser(username: username, password: password, rememberMe: rememberMe), currentTry: 3)

        switch result {
        case .success:
            UserSession.shared.setUserLoggedIn(isLoggedIn: true)
            if rememberMe {
                UserSession.shared.saveUsername(username: username)
                UserSession.shared.savePassword(password: password)
            }

            if let notificationConfig = UserSession.shared.getCurrentNotificationDeviceConfiguration(),
               let deviceToken = notificationConfig.apnsDeviceToken,
               !notificationConfig.skippedNotifications {
                return await PushNotificationServiceFactory.shared.register(deviceToken: deviceToken)
            }
            return .success
        case .failure(let error):
            switch error {
            case let .httpURLResponseError(statusCode, artemisError):
                if statusCode == .forbidden && artemisError == "CAPTCHA required" {
                    return .failure(error: LoginError.captchaRequired)
                }
            default:
                return NetworkResponse(error: error)
            }
            return NetworkResponse(error: error)
        }
    }
}

enum LoginError: Error {
    case captchaRequired
}
