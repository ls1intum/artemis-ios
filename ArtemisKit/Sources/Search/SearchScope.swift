//
//  SearchScope.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 18.03.26.
//

import Foundation

enum SearchScope: Hashable, CaseIterable {
    case course, global

    var title: String {
        switch self {
        case .course: R.string.localizable.thisCourse()
        case .global: R.string.localizable.allCourses()
        }
    }
}
