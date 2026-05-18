//
//  FAQSearchResult.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 18.05.26.
//

import Foundation
import SharedModels
import SwiftUI

struct FAQSearchResult: SearchResultDetails {
    let courseId: Int?
    let courseName: String?

    let faqState: FaqState

    var displayInfo: [Text] { [] }

    func navigateToDetail(with controller: NavigationController, result: SearchResultDTO) async {
        guard let courseId else { return }
        controller.goToCourse(id: courseId)
        controller.setTab(identifier: .faq)
    }
}
