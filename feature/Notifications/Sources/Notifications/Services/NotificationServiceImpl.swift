//
//  File.swift
//  
//
//  Created by Sven Andabaka on 17.03.23.
//

import Foundation
import APIClient
import Common

class NotificationServiceImpl: NotificationService {

    let client = APIClient()

    struct GetNotificationsRequest: APIRequest {
        typealias Response = [Notification]

        let page: Int
        let size: Int

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/notifications?page=\(page)&size=\(size)&sort=notificationDate,desc"
        }
    }

    func loadNotifications(page: Int = 0, size: Int = 50) async -> DataState<[Notification]> {
        let result = await client.sendRequest(GetNotificationsRequest(page: page, size: size))

        switch result {
        case .success((let response, _)):
            return .done(response: response)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }

    struct UpdateUserNotificationDateRequest: APIRequest {
        typealias Response = RawResponse

        var method: HTTPMethod {
            return .put
        }

        var resourceName: String {
            return "api/users/notification-date"
        }
    }

    func updateUserNotificationDate() async -> NetworkResponse {
        let result = await client.sendRequest(UpdateUserNotificationDateRequest())

        switch result {
        case .success:
            return .success
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }
}
