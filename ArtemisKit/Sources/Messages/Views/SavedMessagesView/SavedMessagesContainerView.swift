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
    @State var posts: DataState<[SavedPostDTO]> = .loading
    let courseId: Int

    var body: some View {
        DataStateView(data: $posts) {
            
        } content: { posts in
            List {
                ForEach(posts, id: \.id) { post in
                    Text(post.content)
                }
            }
        }
        .task {
            if posts.value == nil {
                posts = await MessagesServiceFactory.shared.getSavedPosts(for: courseId, status: .inProgress)
            }
        }
    }
}
