//
//  SearchResultsView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 21.03.26.
//

import DesignLibrary
import Navigation
import SwiftUI

struct SearchResultsView: View {
    @Bindable var viewModel: SearchTabViewModel

    var body: some View {
        DataStateView(data: $viewModel.searchResults) {
            await viewModel.performSearch()
        } content: { results in
            if results.isEmpty {
                ContentUnavailableView.search
                    .loadingIndicator(isLoading: $viewModel.isLoading)
            } else {
                ForEach(results, id: \.id) { result in
                    SearchResultView(result: result)
                        .loadingIndicator(isLoading: $viewModel.isLoading)
                }
            }
        }
        .task(id: "getRecents") {
            if case .loading = viewModel.searchResults {
                await viewModel.performSearch()
            }
        }
    }
}

private struct SearchResultView: View {
    @EnvironmentObject private var navController: NavigationController
    let result: SearchResultDTO

    var body: some View {
        Button {
            Task {
                await result.navigate(with: navController)
            }
        } label: {
            VStack(alignment: .leading) {
                HStack {
                    if let title = result.title {
                        Text(title)
                            .font(.headline)
                    }
                    Spacer(minLength: 0)
                    if let badge = result.badge {
                        Chip(text: badge,
                             backgroundColor: .gray,
                             horizontalPadding: .m,
                             verticalPadding: .s)
                        .font(.footnote)
                    }
                }

                if let description = result.description {
                    Text(description)
                        .font(.footnote)
                        .lineLimit(3)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .buttonStyle(.plain)
    }
}
