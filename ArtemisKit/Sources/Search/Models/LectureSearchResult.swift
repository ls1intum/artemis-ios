//
//  LectureSearchResult.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 23.03.26.
//

import Foundation

struct LectureSearchResult: SearchResultDetails {
    let courseId: Int?
    let courseName: String?

    let startDate: Date?
    let endDate: Date?
}
