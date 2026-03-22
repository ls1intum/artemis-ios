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
    var searchTerm = ""
    var scope: SearchScope = .course
    var selectedFilters = [SearchFilter]()

    var searchRequest: SearchRequest {
        .init(type: selectedFilters.first?.apiFilterType,
              courseId: scope == .course ? 0 : nil,
              searchTerm: searchTerm)
    }

    var searchResults: DataState<[SearchResultDTO]> = .loading
    var isLoading = false

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
        isLoading = true

        let service = SearchServiceFactory.shared

        searchResults = await service.search(for: selectedFilters.first?.apiFilterType,
                                             in: scope == .course ? 0 : nil,
                                             searchTerm: searchTerm)
        observeChanges()
        isLoading = false
    }
}
