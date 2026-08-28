//
//  SearchViewModifiers.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 28.08.26.
//

import ProfileInfo
import SwiftUI

extension View {
    public func globalSearchable(searchText: Binding<String>) -> some View {
        modifier(ExternalGlobalSearchViewModifier(searchText: searchText))
    }

    func globalSearchable(viewModel: SearchTabViewModel) -> some View {
        modifier(GlobalSearchViewModifier(viewModel: viewModel))
    }
}

struct ExternalGlobalSearchViewModifier: ViewModifier {
    @State private var viewModel: SearchTabViewModel
    @Binding var searchText: String
    @FeatureAvailability(.globalSearch) private var searchAvailable

    init(searchText: Binding<String>) {
        self._viewModel = State(initialValue: .init(courseId: 0, irisEnabled: false, defaultScope: .global, limitResults: 3))
        self._searchText = searchText
    }

    func body(content: Content) -> some View {
        if searchAvailable {
            content
                .animation(.default, value: viewModel.searchResults.value)
                .globalSearchable(viewModel: viewModel)
                .onChange(of: viewModel.searchTerm) { _, newValue in
                    searchText = newValue
                }
        } else {
            content
                .searchable(text: $searchText)
        }
    }
}

struct GlobalSearchViewModifier: ViewModifier {
    @Bindable var viewModel: SearchTabViewModel

    func body(content: Content) -> some View {
        content
            .environment(viewModel)
            .searchable(text: $viewModel.searchTerm, tokens: $viewModel.selectedFilters) { token in
                Label(token.displayTitle, systemImage: token.systemImage)
            }
    }
}
