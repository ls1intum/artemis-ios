//
//  NotificationWebsocketService.swift
//  
//
//  Created by Sven Andabaka on 07.05.23.
//

import Foundation

protocol NotificationWebsocketService {

    /**
     * Subscribe to single user notification, group notification and quiz updates if it was not already subscribed.
     * Then it returns a  AsyncStream the calling component can listen on to actually receive the notifications.
     * @return AsyncStream<Notification>
     */
    func subscribeToNotifications() -> AsyncStream<Notification>
}

enum NotificationWebsocketServiceFactory {

    static let shared: NotificationWebsocketService = NotificationWebsocketServiceImpl.shared
}
