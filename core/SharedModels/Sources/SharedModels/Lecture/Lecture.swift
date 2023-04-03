//
//  File.swift
//
//
//  Created by Sven Andabaka on 27.02.23.
//

import Foundation

public struct Lecture: Codable {
    let id: Int
    let title: String?
    let description: String?
    let startDate: Date?
    let endDate: Date?
    //    let attachments: [Attachment]
}
