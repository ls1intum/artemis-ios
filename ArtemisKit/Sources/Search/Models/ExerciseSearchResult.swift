//
//  ExerciseSearchResult.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 22.03.26.
//

import Foundation

struct ExerciseSearchResult: SearchResultDetails {
    let courseId: Int?
    let courseName: String?

    let dueDate: Date?
    let releaseDate: Date?
    let points: Int?
    let difficulty: String?
}
