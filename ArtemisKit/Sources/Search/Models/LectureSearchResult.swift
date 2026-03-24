//
//  LectureSearchResult.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 23.03.26.
//

import Foundation
import Navigation
import SwiftUI

struct LectureSearchResult: SearchResultDetails {
    let courseId: Int?
    let courseName: String?

    let startDate: Date?
    let endDate: Date?

    var displayInfo: [Text] {
        [] // TODO: Add info
    }

    func navigateToDetail(with controller: NavigationController, result: SearchResultDTO) async {
        guard let courseId,
              let lectureId = Int(result.id ?? "") else { return }
        await controller.goToLecture(courseId: courseId, lectureId: lectureId)
    }
}
