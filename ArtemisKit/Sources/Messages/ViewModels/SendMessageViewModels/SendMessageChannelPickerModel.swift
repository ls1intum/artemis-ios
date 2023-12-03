//
//  SendMessageChannelPickerModel.swift
//
//
//  Created by Nityananda Zbil on 02.12.23.
//

import Common
import SharedModels
import SharedServices
import SwiftUI

class SendMessageChannelPickerModel: BaseViewModel {

    let course: Course

    @Published var channels: DataState<[ChannelIdAndNameDTO]> = .loading

    init(course: Course, conversation: Conversation) {
        self.course = course
    }

    func search(idOrName: String) async {
        isLoading = true
        let channels = await MessagesServiceFactory.shared.getChannelsPublicOverview(for: course.id)
        if case let .done(channels) = channels {
            let filtered = channels.filter { channel in
                channel.name.lowercased().contains(idOrName.lowercased())
            }
            self.channels = .done(response: filtered)
        } else {
            self.channels = channels
        }
        isLoading = false
    }
}
