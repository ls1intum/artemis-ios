//
//  File.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 18.05.26.
//

import Foundation
import SwiftUI

struct ChannelSearchResult: SearchResultDetails {
    let courseId: Int?
    let courseName: String?

    let isPublic: Bool
    let isCourseWide: Bool

    var displayInfo: [Text] { [] }

    func navigateToDetail(with controller: NavigationController, result: SearchResultDTO) async {
        guard let courseId,
              let conversationId = Int(result.id ?? "") else { return }
        controller.goToCourseConversation(courseId: courseId, conversationId: conversationId)
    }
}
