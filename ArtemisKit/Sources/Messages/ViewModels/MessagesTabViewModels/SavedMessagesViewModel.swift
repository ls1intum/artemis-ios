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
}
