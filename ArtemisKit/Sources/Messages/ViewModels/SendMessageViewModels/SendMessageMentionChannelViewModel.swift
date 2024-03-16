//
//  SendMessageMentionChannelViewModel.swift
//
//
//  Created by Nityananda Zbil on 02.12.23.
//

import Common
import SharedModels
import SharedServices
import SwiftUI

@MainActor
@Observable
final class SendMessageMentionChannelViewModel {

    let course: Course

    var channels: DataState<[ChannelIdAndNameDTO]> = .loading

    private let messagesService: MessagesService

    init(
        course: Course,
        messagesService: MessagesService = MessagesServiceFactory.shared
    ) {
        self.course = course
        self.messagesService = messagesService
    }

    func search(idOrName: String) async {
        let channels = await messagesService.getChannelsPublicOverview(for: course.id)
        if case let .done(channels) = channels {
            let filtered = channels.filter { channel in
                let range = channel.name.range(of: idOrName, options: [.caseInsensitive, .diacriticInsensitive])
                return range != nil
            }
            self.channels = .done(response: filtered)
        } else {
            self.channels = channels
        }
    }
}
