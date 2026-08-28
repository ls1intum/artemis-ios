//
//  SearchTabViewModel.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 21.03.26.
//

import Common
import Foundation

@Observable
class SearchTabViewModel {
    let courseId: Int
    let irisEnabled: Bool
    let limitResults: Int?

    var searchTerm = ""
    var scope: SearchScope
    var selectedFilters = [SearchFilter]()

    var searchRequest: SearchRequest {
        .init(type: selectedFilters.first,
              courseId: scope == .course ? courseId : nil,
              searchTerm: searchTerm)
    }

    var searchResults: DataState<[SearchResultDTO]> = .loading
    var isLoading = false

    init(courseId: Int, irisEnabled: Bool, defaultScope: SearchScope = .course, limitResults: Int? = nil) {
        self.courseId = courseId
        self.irisEnabled = irisEnabled
        self.scope = defaultScope
        self.limitResults = limitResults
    }

    private var updateSearchTask: Task<(), Never>?
    /// Observes changes to search request related properties, sending a new request when values change
    private func observeChanges() {
        withObservationTracking {
            _ = searchRequest
        } onChange: { [weak self] in
            guard let self else { return }
            updateSearchTask?.cancel()
            updateSearchTask = Task { [weak self] in
                do {
                    try await Task.sleep(nanoseconds: 350_000_000)
                    await self?.performSearch()
                } catch {
                    // task cancelled -> new change was triggered within 350ms
                }
            }
        }
    }

    func performSearch() async {
        if searchTerm.count >= 3 || searchTerm.isEmpty {
            // Only search if there are 3+ characters (or 0 for suggestion)
            observeChanges()
            return
        }

        isLoading = true

        let service = SearchServiceFactory.shared

        let results = await service.search(for: selectedFilters.first?.apiFilterTypes,
                                             in: scope == .course ? courseId : nil,
                                             searchTerm: searchTerm)

        searchResults = results.map {
            if let limitResults {
                return Array($0.prefix(limitResults))
            }
            return $0
        }

        observeChanges()
        isLoading = false
    }
}
