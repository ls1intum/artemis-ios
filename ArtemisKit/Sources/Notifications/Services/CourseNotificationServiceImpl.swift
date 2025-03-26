//
//  CourseNotificationServiceImpl.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 23.03.25.
//

import APIClient
import Common

class CourseNotificationServiceImpl: CourseNotificationService {

    let client = APIClient()

    struct GetNotificationsRequest: APIRequest {
        typealias Response = CourseNotificationPage

        let courseId: Int
        let page: Int
        let size: Int

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/communication/notification/\(courseId)?page=\(page)&size=\(size)"
        }
    }

    func loadNotifications(courseId: Int, page: Int = 0, size: Int = 50) async -> DataState<[CourseNotification]> {
        let result = await client.sendRequest(GetNotificationsRequest(courseId: courseId, page: page, size: size))

        switch result {
        case .success((let response, _)):
            return .done(response: response.content)
        case .failure(let error):
            return .failure(error: UserFacingError(error: error))
        }
    }
}
