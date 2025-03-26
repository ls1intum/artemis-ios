//
//  NotificationNavigationHandler.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 26.03.25.
//

import Navigation
import SwiftUI

extension View {
    func notificationTapHandler(for notification: CourseNotification) -> some View {
        modifier(NotificationNavigationHandler(notification: notification))
    }
}

private struct NotificationNavigationHandler: ViewModifier {
    @EnvironmentObject var navController: NavigationController
    let notification: CourseNotification

    func body(content: Content) -> some View {
        if let tappable = notification.notification as? TappableNotification {
            Button {
                tappable.handleTap(with: navController)
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
