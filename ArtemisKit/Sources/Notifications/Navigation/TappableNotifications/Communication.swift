//
//  File.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 31.03.25.
//

import Navigation
import PushNotifications

extension NewPostNotification: TappableNotification {
    @MainActor
    func handleTap(with navController: NavigationController) async {
        // CoursePath always exists in context of CourseNotifications
        guard let coursePath = navController.selectedCourse else { return }
        navController.setTab(identifier: .communication)
        guard let channelId else { return }
        navController.selectedPath = ConversationPath(id: Int64(channelId), coursePath: coursePath)
    }
}
