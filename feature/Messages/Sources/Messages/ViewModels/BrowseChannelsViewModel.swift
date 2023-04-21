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
class BrowseChannelsViewModel: ObservableObject {

    @Published var allChannels: DataState<[Channel]> = .loading

    @Published var error: UserFacingError? {
        didSet {
            showError = error != nil
        }
    }
    @Published var showError = false

    private let courseId: Int

    init(courseId: Int) {
        self.courseId = courseId
    }

    func getAllChannels() async {
        allChannels = await MessagesServiceFactory.shared.getChannelsOverview(for: courseId)
    }

    func joinChannel(channelId: Int64) async -> Bool {
        let result = await MessagesServiceFactory.shared.joinChannel(for: courseId, channelId: channelId)

        switch result {
        case .notStarted, .loading:
            return false
        case .success:
            return true
        case .failure(let error):
            self.error = UserFacingError(title: error.localizedDescription)
            return false
        }
    }
}
