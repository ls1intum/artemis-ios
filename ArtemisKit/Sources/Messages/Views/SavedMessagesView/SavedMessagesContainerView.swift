//
//  SavedMessagesContainerView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 15.03.25.
//

import Common
import DesignLibrary
import SwiftUI

struct SavedMessagesContainerView: View {
    @State private var viewModel: SavedMessagesViewModel

    init(courseId: Int) {
        _viewModel = State(initialValue: SavedMessagesViewModel(courseId: courseId))
    }

    var body: some View {
        List {
            FilterBarPicker(selectedFilter: $viewModel.selectedType, hiddenFilters: [])

            Section {
                SavedMessagesView(viewModel: viewModel)
            }
        }
        .refreshable {
            await viewModel.loadPostsForSelectedCategory()
        }
        .navigationTitle(R.string.localizable.savedMessages())
        .navigationBarTitleDisplayMode(.inline)
    }
}
