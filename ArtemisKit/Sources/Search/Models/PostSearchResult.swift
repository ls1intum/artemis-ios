//
//  PostSearchResult.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 18.05.26.
//

import Foundation
import Navigation
import SwiftUI

struct PostSearchResult: SearchResultDetails {
    let courseId: Int?
    let courseName: String?

    let channelId: Int?
    let channelName: String?

    // Answer
    let postId: Int?

    var displayInfo: [Text] { [] }

    func navigateToDetail(with controller: NavigationController, result: SearchResultDTO) async {
        guard let courseId,
              let channelId,
              let messageId = Int(result.id ?? "") else { return }

        await controller.goToThread(for: Int64(postId ?? messageId),
                                    in: .unknown(conversation: .init(id: Int64(channelId))),
                                    of: .init(id: courseId, courseInformationSharingConfiguration: .communicationAndMessaging))
    }
}
