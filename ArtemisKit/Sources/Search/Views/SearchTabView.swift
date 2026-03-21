//
//  SearchTabView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 18.03.26.
//

import Notifications
import SwiftUI

public struct SearchTabView: View {
    @State private var viewModel = SearchTabViewModel()

    public init() {}

    public var body: some View {
        NavigationStack {
            List {
                scopePicker

                scopeSuggestions

                Section {
                    SearchResultsView(results: [])
                }
            }
            .searchable(text: $viewModel.searchTerm, tokens: $viewModel.selectedFilters) { token in
                Label(token.displayTitle, systemImage: token.systemImage)
            }
            .listRowSpacing(15)
            .courseToolbar()
        }
    }

    private var scopePicker: some View {
        Section(R.string.localizable.search()) {
            Picker(selection: $viewModel.scope) {
                ForEach(SearchScope.allCases, id: \.self) { scope in
                    Text(scope.title)
                        .tag(scope)
                }
            } label: {
                Text(R.string.localizable.scope())
            }
            .controlSize(.large)
            .pickerStyle(.segmented)
            .listRowBackground(Color.clear)
            .listRowInsets(EdgeInsets())
        }
    }

    private var scopeSuggestions: some View {
        ForEach(SearchFilter.allCases) { filter in
            ScopeSuggestion(viewModel: viewModel, filter: filter)
        }
    }
}

private struct ScopeSuggestion: View {
    let viewModel: SearchTabViewModel
    let filter: SearchFilter

    var body: some View {
        if viewModel.selectedFilters.isEmpty || filter == .iris {
            Group {
                if filter == .iris {
                    NavigationLink {
                        // TODO: Iris does not exist yet
                        // This could open Iris, providing the entered text as input
                    } label: {
                        label
                            .overlay(alignment: .bottomLeading) {
                                Text("Not available yet")
                            }
                    }
                    .navigationLinkIndicatorVisibility(.hidden)
                    .disabled(true)
                } else {
                    Button {
                        withAnimation {
                            viewModel.selectedFilters.append(filter)
                        }
                    } label: {
                        label
                    }
                }
            }
            .buttonStyle(.plain)
            .listRowBackground(filter.color.opacity(0.5))
            .transition(.slide.combined(with: .opacity))
        }
    }

    private var label: some View {
        ZStack {
            Text(filter.displayTitle)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .font(.title)
            Image(systemName: filter.systemImage)
                .resizable()
                .scaledToFit()
                .padding(10)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .opacity(0.3)
        }
        .frame(height: 70)
        .contentShape(.rect)
    }
}
