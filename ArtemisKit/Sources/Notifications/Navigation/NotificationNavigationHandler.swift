//
//  NotificationNavigationHandler.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 26.03.25.
//

import Navigation
import PushNotifications
import SwiftUI

extension View {
    func notificationTapHandler(for notification: CourseNotification) -> some View {
        modifier(NotificationNavigationHandler(notification: notification))
    }
}

private struct NotificationNavigationHandler: ViewModifier {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var navController: NavigationController
    let notification: CourseNotification

    func body(content: Content) -> some View {
        if let tappable = notification.notification.displayable as? NavigatableNotification {
            Button {
                if let path = tappable.relativePath {
                    dismiss()
                    DeeplinkHandler.shared.handle(path: path)
                }
            } label: {
                content
            }
            .contentShape(.rect)
            .buttonStyle(.plain)
        } else {
            content
        }
    }
}
