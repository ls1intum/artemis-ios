//
//  File.swift
//
//
//  Created by Sven Andabaka on 16.02.23.
//

import Foundation
import Common

public protocol PushNotificationService {

    /**
     * Register Device to receive Push Notifications
     */
    func register() async -> NetworkResponse

    /**
     * Unregister Device to receive Push Notifications
     */
    func unregister() async -> NetworkResponse
}

enum PushNotificationServiceFactory {

    static let shared: PushNotificationService = PushNotificationServiceImpl()
}
