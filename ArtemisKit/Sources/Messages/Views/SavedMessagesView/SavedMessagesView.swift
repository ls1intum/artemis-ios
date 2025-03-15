//
//  SavedMessagesView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 15.03.25.
//

import Common
import DesignLibrary
import SwiftUI

struct SavedMessagesView: View {
    @Bindable var viewModel: SavedMessagesViewModel
    var postsBinding: Binding<DataState<[SavedPostDTO]>> {
        Binding {
            viewModel.displayedPosts
        } set: { _ in
        }
    }

    var body: some View {
        DataStateView(data: postsBinding) {
            await viewModel.loadPostsForSelectedCategory()
        } content: { posts in
            if posts.isEmpty {
                Section {
                    ContentUnavailableView(R.string.localizable.noMessages(), systemImage: viewModel.selectedType.iconName)
                }
            }
            ForEach(posts.sorted()) { post in
                SavedMessageView(viewModel: viewModel, post: post)
            }
        }
        .task {
            await viewModel.loadPostsForSelectedCategory()
        }
    }
}
