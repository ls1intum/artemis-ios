//
//  SearchService.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 21.03.26.
//

import Common

protocol SearchService {
    /// Send a GET Request to the server to perform a search with the given term and type in the given course.
    /// If no type is specified, all types may be returned.
    /// If no courseId is specified, the search is performed globally across all courses the user can access.
    func search(for types: [SearchFilterType]?, in courseId: Int?, searchTerm: String) async -> DataState<[SearchResultDTO]>
}

enum SearchServiceFactory: DependencyFactory {
    static let liveValue: SearchService = SearchServiceImpl()
}
