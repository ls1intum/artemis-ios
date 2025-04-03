//
//  NotificationIconView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 23.03.25.
//

import DesignLibrary
import UserStore
import SwiftUI

struct NotificationIconView: View {
    let notification: CourseNotification

    var body: some View {
        switch notification.notification {
        case .newPost(let postNotification):
            profilePicture(name: postNotification.authorName,
                           id: postNotification.authorId,
                           url: postNotification.authorImageUrl)
        case .newAnnouncement(let postNotification):
            profilePicture(name: postNotification.authorName,
                           id: postNotification.authorId,
                           url: postNotification.authorImageUrl)
        case .newAnswer(let postNotification):
            profilePicture(name: postNotification.replyAuthorName,
                           id: postNotification.replyAuthorId,
                           url: postNotification.replyImageUrl)
        case .newMention(let postNotification):
            profilePicture(name: postNotification.replyAuthorName ?? postNotification.postAuthorName,
                           id: postNotification.replyAuthorId,
                           url: postNotification.replyImageUrl)
        default:
            EmptyView()
        }
    }

    @ViewBuilder
    func profilePicture(name: String?, id: Int?, url: String?) -> some View {
        if let url, let baseUrl = UserSessionFactory.shared.institution?.baseURL {
            ArtemisAsyncImage(imageURL: baseUrl.appending(path: url)) {}
        } else if let name, let id {
            ProfilePictureInitialsView(name: name, userId: "\(id)", size: 50)
                .clipShape(.rect(cornerRadius: .m))
        }
    }
}
