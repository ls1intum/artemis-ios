//
//  File.swift
//  
//
//  Created by Sven Andabaka on 23.04.23.
//

import Foundation
import Common

class CreateChannelViewModel: BaseViewModel {

    @Published var nameFormatText: String?

    func createChannel(for courseId: Int, name: String, description: String?, isPrivate: Bool, isAnnouncement: Bool) async -> Bool {
        if !validateChannelName(name: name) {
            return false
        }

        let result = await MessagesServiceFactory.shared.createChannel(for: courseId,
                                                                       name: name,
                                                                       description: description,
                                                                       isPrivate: isPrivate,
                                                                       isAnnouncement: isAnnouncement)

        switch result {
        case .notStarted, .loading:
            return false
        case .success:
            return true
        case .failure(let error):
            presentError(userFacingError: UserFacingError(title: error.localizedDescription))
            return false
        }
    }

    private func validateChannelName(name: String) -> Bool {
        let regex = "^[a-z0-9-]+$"
        let isValid = name.range(of: regex, options: .regularExpression) != nil
        if isValid {
            nameFormatText = nil
        } else {
            nameFormatText = "Names can only contain lowercase letters, numbers, and dashes. Only Artemis can create channels that start with a $."
        }
        return isValid
    }
}
