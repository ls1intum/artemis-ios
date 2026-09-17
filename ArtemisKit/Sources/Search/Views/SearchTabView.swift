//
//  SearchTabView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 18.03.26.
//

import Navigation
import Notifications
import ProfileInfo
import SwiftUI
import UserStore

public struct SearchTabView: View {
    @State private var viewModel: SearchTabViewModel

    public init(courseId: Int, irisEnabled: Bool) {
        _viewModel = State(initialValue: SearchTabViewModel(courseId: courseId, irisEnabled: irisEnabled))
    }

    public var body: some View {
        NavigationStack {
            List {
                scopePicker

                GlobalSearchSection()

                // Search text field does not count to Safe Area while open, so create some space
                Spacer().listRowBackground(Color.clear)
            }
            .animation(.default, value: viewModel.selectedFilters)
            .animation(.default, value: viewModel.searchTerm.isEmpty)
            .submitLabel(.search)
            .globalSearchable(viewModel: viewModel)
            .listRowSpacing(.m)
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
}

public struct GlobalSearchSection: View {
    @FeatureAvailability(.globalSearch) private var searchAvailable

    public init() {}

    public var body: some View {
        if searchAvailable {
            GlobalSearchSectionContent()
        }
    }
}

// Split into two parts such that @Environment cannot be accessed
// accidentally when global search is disabled
private struct GlobalSearchSectionContent: View {
    @EnvironmentObject private var navController: NavigationController
    @Environment(SearchTabViewModel.self) private var viewModel

    var body: some View {
        scopeSuggestions

        Section {
            SearchResultsView(viewModel: viewModel)
        }
    }

    @ViewBuilder private var scopeSuggestions: some View {
        if viewModel.irisEnabled && UserSessionFactory.shared.user?.selectedLLMUsage?.isAIEnabled == true {
            ScopeSuggestion(viewModel: viewModel, filter: .iris) {
                navController.openNewIrisChat(courseId: viewModel.courseId, inputText: viewModel.searchTerm)
            }
            .listRowInsets(EdgeInsets(top: .s, leading: .s, bottom: .s, trailing: .s))
            .listRowBackground(Color.clear)
        }

        if viewModel.selectedFilters.isEmpty && viewModel.searchTerm.isEmpty {
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
    var action: (() -> Void)?

    var body: some View {
        Button {
            if let action {
                action()
            } else {
                withAnimation {
                    viewModel.selectedFilters.append(filter)
                }
            }
        } label: {
            label
        }
        .buttonStyle(.plain)
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
