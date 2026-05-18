//
//  FAQSearchResult.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 18.05.26.
//

import Foundation
import Navigation
import SharedModels
import SwiftUI

struct FAQSearchResult: SearchResultDetails {
    let courseId: Int?
    let courseName: String?

    let faqState: FaqState

    var displayInfo: [Text] { [] }

    func navigateToDetail(with controller: NavigationController, result: SearchResultDTO) async {
        guard let courseId else { return }
        await controller.goToCourse(id: courseId)
        await controller.setTab(identifier: .faq)
    }
}
