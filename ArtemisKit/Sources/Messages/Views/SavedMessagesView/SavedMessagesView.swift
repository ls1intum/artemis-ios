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
            ForEach(posts) { post in
                Text(post.content)
            }
        }
        .animation(.default, value: viewModel.displayedPosts.value)
        .task {
            await viewModel.loadPostsForSelectedCategory()
        }
    }
}
