//
//  SendMessageChannelPickerViewModel.swift
//
//
//  Created by Nityananda Zbil on 02.12.23.
//

import Common
import SharedModels
import SharedServices
import SwiftUI

@Observable
class SendMessageChannelPickerViewModel {

    let course: Course

    var channels: DataState<[ChannelIdAndNameDTO]> = .loading

    init(course: Course, conversation: Conversation) {
        self.course = course
    }

    func search(idOrName: String) async {
        let channels = await MessagesServiceFactory.shared.getChannelsPublicOverview(for: course.id)
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
