//
//  File.swift
//  
//
//  Created by Sven Andabaka on 23.04.23.
//

import Foundation
import Common
import SwiftUI

@MainActor
@Observable
class CreateChannelViewModel {

    var error: UserFacingError?
    var showError: Binding<Bool> {
        Binding(get: {
            self.error != nil
        }, set: { newValue in
            if !newValue {
                self.error = nil
            }
        })
    }

    var nameFormatText: String?

    var name = ""
    var description = ""
    var channelType: ChannelType = .public
    var isAnnouncement = false

    func createChannel(for courseId: Int) async -> Int64? {
        if !validateChannelName(name: name) {
            return nil
        }

        let channelDescription = description.isEmpty ? nil : description
        let messagesService = MessagesServiceFactory.shared
        let result = await messagesService.createChannel(for: courseId,
                                                         name: name,
                                                         description: channelDescription,
                                                         isPrivate: channelType.isPrivate,
                                                         isAnnouncement: isAnnouncement,
                                                         isCourseWide: channelType.isCourseWide)

        switch result {
        case .loading:
            return nil
        case .failure(let error):
            self.error = error
            return nil
        case .done(let response):
            return response.id
        }
    }

    private func validateChannelName(name: String) -> Bool {
        let regex = "^[a-z0-9-]+$"
        let isValid = name.range(of: regex, options: .regularExpression) != nil
        if isValid {
            nameFormatText = nil
        } else {
            nameFormatText = R.string.localizable.channelNameWarningText()
        }
        return isValid
    }
}

enum ChannelType: CaseIterable, Hashable {
    case `private`, `public`, courseWide

    var isPrivate: Bool {
        self == .private
    }

    var isCourseWide: Bool {
        self == .courseWide
    }

    var title: String {
        switch self {
        case .public:
            R.string.localizable.publicChannelLabel()
        case .private:
            R.string.localizable.privateChannelLabel()
        case .courseWide:
            R.string.localizable.courseWideChannelLabel()
        }
    }

    var description: String {
        switch self {
        case .public:
            R.string.localizable.publicChannelDescription()
        case .private:
            R.string.localizable.privateChannelDescription()
        case .courseWide:
            R.string.localizable.courseWideChannelDescription()
        }
    }
}
