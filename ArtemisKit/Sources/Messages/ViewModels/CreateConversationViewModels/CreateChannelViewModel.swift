//
//  File.swift
//  
//
//  Created by Sven Andabaka on 23.04.23.
//

import Foundation
import Common

@MainActor
class CreateChannelViewModel: BaseViewModel {

    @Published var nameFormatText: String?

    func createChannel(for courseId: Int, name: String, description: String?, isPrivate: Bool, isAnnouncement: Bool) async -> Int64? {
        if !validateChannelName(name: name) {
            return nil
        }

        let result = await MessagesServiceFactory.shared.createChannel(for: courseId,
                                                                       name: name,
                                                                       description: description,
                                                                       isPrivate: isPrivate,
                                                                       isAnnouncement: isAnnouncement)

        switch result {
        case .loading:
            return nil
        case .failure(let error):
            presentError(userFacingError: error)
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
