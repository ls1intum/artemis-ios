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

    struct GetNotificationSettingsRequest: APIRequest {
        typealias Response = [PushNotificationSetting]

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/notification-settings"
        }
    }

    func getNotificationSettings() async -> DataState<[PushNotificationSetting]> {
        let result = await client.sendRequest(GetNotificationSettingsRequest())

        switch result {
        case .success(let (response, _)):
            return .done(response: response)
        case .failure(let error):
            log.error(error, "Could not load Notification Settings")
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct SaveNotificationSettingsRequest: APIRequest {
        typealias Response = [PushNotificationSetting]

        var notificationSettings: [PushNotificationSetting]

        var method: HTTPMethod {
            return .put
        }

        var resourceName: String {
            return "api/notification-settings"
        }

        func encode(to encoder: Encoder) throws {
            var container = encoder.singleValueContainer()
            try container.encode(notificationSettings)
        }
    }

    func saveNotificationSettings(_ settings: [PushNotificationSetting]) async -> DataState<[PushNotificationSetting]> {
        let result = await client.sendRequest(SaveNotificationSettingsRequest(notificationSettings: settings))

        switch result {
        case .success(let (response, _)):
            return .done(response: response)
        case .failure(let error):
            log.error(error, "Could not save Notification Settings")
            return .failure(error: UserFacingError(error: error))
        }
    }
}
