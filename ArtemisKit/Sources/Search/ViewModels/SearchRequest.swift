//
//  SearchRequest.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 22.03.26.
//

import Foundation

struct SearchRequest: Hashable {
    let type: SearchFilterType?
    let courseId: Int?
    let searchTerm: String
}
