//
//  File.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 31.03.25.
//

import Navigation
import PushNotifications
import SharedModels

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

extension NewAnswerNotification: TappableNotification {
    @MainActor
    func handleTap(with navController: NavigationController) async {
        // CoursePath always exists in context of CourseNotifications
        guard let coursePath = navController.selectedCourse else { return }
        navController.setTab(identifier: .communication)
        guard let channelId, let postId else { return }
        // TODO: Add proper loading for channel
        var conversation = Channel(id: Int64(channelId))
        if let channelName {
            conversation.name = channelName
        }
        navController.selectedPath = ConversationPath(id: Int64(channelId), coursePath: coursePath)
        let threadPath = ThreadPath(postId: Int64(postId), conversation: .channel(conversation: conversation), coursePath: coursePath)
        navController.tabPath.append(threadPath)
    }
}

extension NewAnnouncementNotification: TappableNotification {
    @MainActor
    func handleTap(with navController: NavigationController) async {
        // CoursePath always exists in context of CourseNotifications
        guard let coursePath = navController.selectedCourse else { return }
        navController.setTab(identifier: .communication)
        guard let channelId else { return }
        navController.selectedPath = ConversationPath(id: Int64(channelId), coursePath: coursePath)
    }
}

extension NewMentionNotification: TappableNotification {
    @MainActor
    func handleTap(with navController: NavigationController) async {
        // CoursePath always exists in context of CourseNotifications
        guard let coursePath = navController.selectedCourse else { return }
        navController.setTab(identifier: .communication)
        guard let channelId, let postId else { return }
        // TODO: Add proper loading for channel
        var conversation = Channel(id: Int64(channelId))
        if let channelName {
            conversation.name = channelName
        }
        navController.selectedPath = ConversationPath(id: Int64(channelId), coursePath: coursePath)
        let threadPath = ThreadPath(postId: Int64(postId), conversation: .channel(conversation: conversation), coursePath: coursePath)
        navController.tabPath.append(threadPath)
    }
}
