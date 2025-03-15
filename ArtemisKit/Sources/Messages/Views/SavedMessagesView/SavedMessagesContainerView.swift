//
//  SavedMessagesContainerView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 15.03.25.
//

import Common
import DesignLibrary
import Faq
import SharedModels
import SwiftUI

struct SavedMessagesContainerView: View {
    @State private var viewModel: SavedMessagesViewModel

    init(course: Course) {
        _viewModel = State(initialValue: SavedMessagesViewModel(course: course))
    }

    var body: some View {
        List {
            FilterBarPicker(selectedFilter: $viewModel.selectedType, hiddenFilters: [])

            SavedMessagesView(viewModel: viewModel)
                .listSectionSpacing(.compact)
        }
        .loadingIndicator(isLoading: $viewModel.isLoading)
        .refreshable {
            await viewModel.loadPostsForSelectedCategory()
        }
        .navigationTitle(R.string.localizable.savedMessages())
        .navigationBarTitleDisplayMode(.inline)
        .navigationDestination(for: FaqPath.self) { path in
            FaqPathView(path: path)
        }
    }
}
