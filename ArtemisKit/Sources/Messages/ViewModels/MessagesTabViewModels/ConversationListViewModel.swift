//
//  ConversationListViewModel.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 18.12.24.
//

import Combine
import DesignLibrary
import SharedModels
import SwiftUI

@Observable
@MainActor
class ConversationListViewModel {
    let parentViewModel: MessagesAvailableViewModel

    var filter: ConversationFilter = .all
    var searchText = ""

    var conversations: [Conversation]
    var favoriteConversations = [BaseConversation]()

    var channels = [Channel]()
    var exercises = [Channel]()
    var lectures = [Channel]()
    var exams = [Channel]()
    var groupChats = [GroupChat]()
    var oneToOneChats = [OneToOneChat]()

    var hiddenConversations = [BaseConversation]()

    var searchResults: [Conversation] {
        conversations.filter {
            $0.baseConversation.conversationName.localizedStandardContains(searchText)
        }
    }

    var cancellables = Set<AnyCancellable>()

    init(parentViewModel: MessagesAvailableViewModel, conversations: [Conversation]) {
        self.parentViewModel = parentViewModel
        self.conversations = conversations
        trackFilterUpdates()
        trackConversationUpdates()
        updateConversations()
    }

    /// Track updates to `filter` and call `updateConversations()` on change
    private func trackFilterUpdates() {
        withObservationTracking {
            _ = filter
        } onChange: { [weak self] in
            DispatchQueue.main.async { [weak self] in
                withAnimation {
                    self?.updateConversations()
                }
                self?.trackFilterUpdates()
            }
        }
    }

    /// Track updates to `parentViewModel.allConversations` and call `updateConversations()` on change
    private func trackConversationUpdates() {
        parentViewModel.$allConversations
            .dropFirst()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] updated in
                if let newValue = updated.value,
                   newValue != self?.conversations {
                    withAnimation {
                        self?.conversations = newValue
                        self?.updateConversations()
                    }
                }
            }.store(in: &cancellables)
    }

    /// Update list of conversations to show correct ones
    private func updateConversations() {
        let course = parentViewModel.course

        updateFilter()

        let notHiddenConversations = conversations.filter {
            !($0.baseConversation.isHidden ?? false)
        }

        favoriteConversations = notHiddenConversations
            .filter {
                $0.baseConversation.isFavorite ?? false && filter.matches($0.baseConversation, course: course)
            }
            .map { $0.baseConversation }

        channels = notHiddenConversations
            .compactMap { $0.baseConversation as? Channel }
            .filter { ($0.subType ?? .general) == .general && filter.matches($0, course: course) }

        exercises = notHiddenConversations
            .compactMap { $0.baseConversation as? Channel }
            .filter { ($0.subType ?? .general) == .exercise && filter.matches($0, course: course) }

        lectures = notHiddenConversations
            .compactMap { $0.baseConversation as? Channel }
            .filter { ($0.subType ?? .general) == .lecture && filter.matches($0, course: course) }

        exams = notHiddenConversations
            .compactMap { $0.baseConversation as? Channel }
            .filter { ($0.subType ?? .general) == .exam && filter.matches($0, course: course) }

        groupChats = notHiddenConversations
            .compactMap { $0.baseConversation as? GroupChat }
            .filter { filter.matches($0, course: course) }

        oneToOneChats = notHiddenConversations
            .compactMap { $0.baseConversation as? OneToOneChat }
            .filter { filter.matches($0, course: course) }

        hiddenConversations = conversations
            .filter { $0.baseConversation.isHidden ?? false && filter.matches($0.baseConversation, course: course) }
            .map { $0.baseConversation }
    }

    /// Reset filter to all if there are no more matches
    private func updateFilter() {
        let course = parentViewModel.course
        // Turn off filter if no matches exist
        if filter != .all && !conversations.contains(where: { conversation in
            filter.matches(conversation.baseConversation, course: course)
        }) {
            filter = .all
        }
    }
}

enum ConversationFilter: FilterPicker {

    case all, unread, recent

    var displayName: String {
        return switch self {
        case .all:
            R.string.localizable.allFilter()
        case .unread:
            R.string.localizable.unreadFilter()
        case .recent:
            R.string.localizable.recentFilter()
        }
    }

    var iconName: String {
        return switch self {
        case .all:
            "tray.2"
        case .unread:
            "app.badge"
        case .recent:
            "clock"
        }
    }

    var selectedColor: Color {
        return switch self {
        case .all:
            Color.blue
        case .unread:
            Color.indigo
        case .recent:
            Color.orange
        }
    }

    var id: Int {
        hashValue
    }

    func matches(_ conversation: BaseConversation, course: Course) -> Bool {
        switch self {
        case .all:
            true
        case .unread:
            conversation.unreadMessagesCount ?? 0 > 0
        case .recent:
            isRecent(channel: conversation, course: course)
        }
    }

    private func isRecent(channel: BaseConversation, course: Course) -> Bool {
        guard let channel = channel as? Channel else {
            return false
        }

        let exercise = course.exercises?.first { $0.id == channel.subTypeReferenceId }
        let lecture = course.lectures?.first { $0.id == channel.subTypeReferenceId }
        let dateStart = Date.now.addingTimeInterval(-5 * 24 * 60 * 60)
        let dateEnd = Date.now.addingTimeInterval(10 * 24 * 60 * 60)
        let range = dateStart...dateEnd

        if let exercise {
            let start = exercise.baseExercise.releaseDate ?? .distantPast
            let end = exercise.baseExercise.dueDate ?? .distantFuture
            return range.contains(start) || range.contains(end)
        }
        if let lecture {
            let start = lecture.startDate ?? .distantPast
            let end = lecture.endDate ?? .distantFuture
            return range.contains(start) || range.contains(end)
        }

        return false
    }
}
