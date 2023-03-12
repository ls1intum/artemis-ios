//
//  File.swift
//
//
//  Created by Sven Andabaka on 16.02.23.
//

import Foundation
import APIClient
import UserStore
import Common

class PushNotificationServiceImpl: PushNotificationService {

    let client = APIClient()

    struct UnregisterRequest: APIRequest {
        typealias Response = RawResponse

        var token: String
        var deviceType = "APNS"

        var method: HTTPMethod {
            return .delete
        }

        var resourceName: String {
            return "api/push_notification/unregister"
        }
    }

    func unregister() async -> NetworkResponse {
        guard let notificationConfiguration = UserSession.shared.getCurrentNotificationDeviceConfiguration(),
              !notificationConfiguration.skippedNotifications else {
            return .success
        }
        guard let deviceToken = notificationConfiguration.apnsDeviceToken else { return .failure(error: APIClientError.wrongParameters)}
        let result = await client.sendRequest(UnregisterRequest(token: deviceToken))

        switch result {
        case .success:
            return .success
        case .failure(let error):
            switch error {
            case .httpURLResponseError(statusCode: .notFound, _):
                return .success
            default:
                return .failure(error: error)
            }
        }
    }

    struct RegisterResponse: Codable {
        let secretKey: String
        let algorithm: String
    }

    struct RegisterRequest: APIRequest {
        typealias Response = RegisterResponse

        var token: String
        var deviceType = "APNS"

        var method: HTTPMethod {
            return .post
        }

        var resourceName: String {
            return "api/push_notification/register"
        }
    }

    func register(deviceToken: String) async -> NetworkResponse {
        let result = await client.sendRequest(RegisterRequest(token: deviceToken))

        switch result {
        case .success(let response):
            UserSession.shared.saveNotificationDeviceConfiguration(token: deviceToken, encryptionKey: response.0.secretKey, skippedNotifications: false)
            return .success
        case .failure(let error):
            UserSession.shared.notificationSetupError = UserFacingError(error: error)
            return .failure(error: error)
        }
    }
}
