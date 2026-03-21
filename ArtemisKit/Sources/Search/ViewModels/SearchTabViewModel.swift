//
//  File.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 21.03.26.
//

import Foundation

@Observable
class SearchTabViewModel {
    var searchTerm = ""
    var scope: SearchScope = .course
    var selectedFilters = [SearchFilter]()
}
