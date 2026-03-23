//
//  SearchResultsView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 21.03.26.
//

import DesignLibrary
import SwiftUI

struct SearchResultsView: View {
    @Bindable var viewModel: SearchTabViewModel

    var body: some View {
        DataStateView(data: $viewModel.searchResults) {
            await viewModel.performSearch()
        } content: { results in
            Group {
                if results.isEmpty {
                    ContentUnavailableView.search
                } else {
                    // TODO: Show search results
                    Text("\(results.count) results")
                }
            }
            .loadingIndicator(isLoading: $viewModel.isLoading)
        }
        .task(id: "getRecents") {
            if case .loading = viewModel.searchResults {
                await viewModel.performSearch()
            }
        }
    }
}
