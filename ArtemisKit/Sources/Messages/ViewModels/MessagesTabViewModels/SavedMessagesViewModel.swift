//
//  SavedMessagesViewModel.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 15.03.25.
//

import Common
import Foundation
import SharedModels
import SwiftUI

@Observable
class SavedMessagesViewModel {
    let service = MessagesServiceFactory.shared

    let course: Course

    var selectedType: SavedPostStatus = .inProgress

    var inProgressPosts: DataState<[SavedPostDTO]> = .loading
    var completedPosts: DataState<[SavedPostDTO]> = .loading
    var archivedPosts: DataState<[SavedPostDTO]> = .loading
    var displayedPosts: DataState<[SavedPostDTO]> {
        switch selectedType {
        case .inProgress:
            inProgressPosts
        case .completed:
            completedPosts
        case .archived:
            archivedPosts
        }
    }

    var isLoading = false
    var error: UserFacingError?
    var showError: Binding<Bool> {
        Binding {
            self.error != nil
        } set: { newValue in
            if !newValue {
                self.error = nil
            }
        }
    }

    init(course: Course) {
        self.course = course
    }

    @MainActor
    func loadPostsForSelectedCategory() async {
        let selectedType = self.selectedType // We are dealing with async, user might change while waiting
        let result = await service.getSavedPosts(for: course.id, status: selectedType)
        withAnimation {
            switch selectedType {
            case .inProgress:
                inProgressPosts = result
            case .completed:
                completedPosts = result
            case .archived:
                archivedPosts = result
            }
        }
    }

    func updatePostStatus(of post: SavedPostDTO, to newStatus: SavedPostStatus) async {
        let selectedType = self.selectedType
        isLoading = true
        defer {
            isLoading = false
        }

        let result = await service.updateSavedPostStatus(for: post.id, with: post.postingType, status: newStatus)
        switch result {
        case .success:
            withAnimation {
                move(post: post, from: selectedType, to: newStatus)
            }
        case .failure(let error):
            self.error = .init(title: "Failed to update status: \(error.localizedDescription)")
        default:
            break
        }
    }

    private func move(post: SavedPostDTO, from: SavedPostStatus, to: SavedPostStatus) {
        switch from {
        case .inProgress:
            inProgressPosts.value?.removeAll { $0.id == post.id }
        case .completed:
            completedPosts.value?.removeAll { $0.id == post.id }
        case .archived:
            archivedPosts.value?.removeAll { $0.id == post.id }
        }
        switch to {
        case .inProgress:
            inProgressPosts.value?.append(post)
        case .completed:
            completedPosts.value?.append(post)
        case .archived:
            archivedPosts.value?.append(post)
        }
    }
}
