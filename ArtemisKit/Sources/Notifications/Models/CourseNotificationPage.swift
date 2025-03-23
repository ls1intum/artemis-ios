//
//  CourseNotificationPage.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 23.03.25.
//

import Foundation

struct CourseNotificationPage: Codable {
    let pageNumber: Int
    let pageSize: Int
    let totalElements: Int
    let totalPages: Int
    let content: [CourseNotification]
}
