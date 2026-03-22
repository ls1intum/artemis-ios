//
//  SearchResultDetails.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 22.03.26.
//

import Foundation

protocol SearchResultDetails: Decodable {
    var courseId: Int? { get }
    var courseName: String? { get }
}
