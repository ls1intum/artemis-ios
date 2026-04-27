//
//  SearchTabView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 18.03.26.
//

import Notifications
import SwiftUI

public struct SearchTabView: View {
    @State private var viewModel: SearchTabViewModel

    public init(courseId: Int) {
        _viewModel = State(initialValue: SearchTabViewModel(courseId: courseId))
    }

    public var body: some View {
        NavigationStack {
            List {
                scopePicker

                scopeSuggestions

                Section {
                    SearchResultsView(viewModel: viewModel)
                }

                // Search text field does not count to Safe Area while open, so create some space
                Spacer().listRowBackground(Color.clear)
            }
            .animation(.default, value: viewModel.selectedFilters)
            .submitLabel(.search)
            .searchable(text: $viewModel.searchTerm, tokens: $viewModel.selectedFilters) { token in
                Label(token.displayTitle, systemImage: token.systemImage)
            }
            .listRowSpacing(.s)
            .listSectionSpacing(.compact)
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

    @ViewBuilder private var scopeSuggestions: some View {
        NavigationLink {
            // TODO: Iris does not exist yet
            // This could open Iris, providing the entered text as input
        } label: {
            ScopeSuggestion(viewModel: viewModel, filter: .iris)
        }
        .navigationLinkIndicatorVisibility(.hidden)
        .disabled(true)
        .listRowInsets(EdgeInsets(top: .m, leading: .s, bottom: .s, trailing: .s))
        .listRowBackground(Color.clear)

        if viewModel.selectedFilters.isEmpty {
            LazyVGrid(columns: [.init(.adaptive(minimum: 150, maximum: 500))]) {
                ForEach(SearchFilter.allCases.filter { $0 != .iris }) { filter in
                    ScopeSuggestion(viewModel: viewModel, filter: filter)
                }
            }
            .listRowInsets(EdgeInsets(top: .s, leading: .s, bottom: .m, trailing: .s))
            .listRowBackground(Color.clear)
        }
    }
}

private struct ScopeSuggestion: View {
    let viewModel: SearchTabViewModel
    let filter: SearchFilter

    var body: some View {
        Button {
            viewModel.selectedFilters.append(filter)
        } label: {
            label
        }
        .buttonStyle(.plain)
        .listRowBackground(filter.color.opacity(0.5))
        .background(filter.color.opacity(0.5), in: .rect(cornerRadius: .m * 1.5))
    }

    private var label: some View {
        ZStack {
            Text(filter.displayTitle)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .font(.title2)
            Image(systemName: filter.systemImage)
                .resizable()
                .scaledToFit()
                .padding(.m)
                .frame(maxWidth: .infinity, alignment: .trailing)
                .opacity(0.25)
        }
        .frame(height: 50)
        .frame(maxWidth: .infinity)
        .padding(.m)
        .contentShape(.rect)
    }
}
