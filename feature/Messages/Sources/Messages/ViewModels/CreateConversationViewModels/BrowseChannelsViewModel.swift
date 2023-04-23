//
//  File.swift
//  
//
//  Created by Sven Andabaka on 21.04.23.
//

import Foundation
import Common
import SharedModels

@MainActor
class BrowseChannelsViewModel: BaseViewModel {

    @Published var allChannels: DataState<[Channel]> = .loading

    let courseId: Int

    init(courseId: Int) {
        self.courseId = courseId
    }

    func getAllChannels() async {
        allChannels = await MessagesServiceFactory.shared.getChannelsOverview(for: courseId)
    }

    func joinChannel(channelId: Int64) async -> Int64? {
        let result = await MessagesServiceFactory.shared.joinChannel(for: courseId, channelId: channelId)

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
}
