//
//  ConversationListViewModel.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 18.12.24.
//

import Combine
import Common
import DesignLibrary
import SharedModels
import SwiftUI

@Observable
@MainActor
class ConversationListViewModel {
    let parentViewModel: MessagesAvailableViewModel

    var filter: ConversationFilter = .all

    var conversations: [Conversation]

    var favoriteConversations = [BaseConversation]()
    var channels = [Channel]()
    var exercises = [Channel]()
    var lectures = [Channel]()
    var exams = [Channel]()
    var groupChats = [GroupChat]()
    var oneToOneChats = [OneToOneChat]()
    var hiddenConversations = [BaseConversation]()

    var unresolvedIds = [Int64]()
    var showUnresolvedLoadingIndicator = false
    var allChannelsResolved = false

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
                defer {
                    self?.trackFilterUpdates()
                }
                if self?.filter == .unresolved {
                    Task {
                        await self?.loadUnresolvedChannels()
                    }
                    return
                }
                withAnimation {
                    self?.updateConversations()
                }
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
        updateFilter()

        let notHiddenConversations = conversations.filter {
            !($0.baseConversation.isHidden ?? false)
        }

        favoriteConversations = notHiddenConversations
            .map { $0.baseConversation }
            .filter {
                $0.isFavorite ?? false && filter.matches($0, viewModel: self)
            }

        channels = notHiddenConversations
            .compactMap { $0.baseConversation as? Channel }
            .filter { ($0.subType ?? .general) == .general && filter.matches($0, viewModel: self) }

        exercises = notHiddenConversations
            .compactMap { $0.baseConversation as? Channel }
            .filter { ($0.subType ?? .general) == .exercise && filter.matches($0, viewModel: self) }

        lectures = notHiddenConversations
            .compactMap { $0.baseConversation as? Channel }
            .filter { ($0.subType ?? .general) == .lecture && filter.matches($0, viewModel: self) }

        exams = notHiddenConversations
            .compactMap { $0.baseConversation as? Channel }
            .filter { ($0.subType ?? .general) == .exam && filter.matches($0, viewModel: self) }

        groupChats = notHiddenConversations
            .compactMap { $0.baseConversation as? GroupChat }
            .filter { filter.matches($0, viewModel: self) }

        oneToOneChats = notHiddenConversations
            .compactMap { $0.baseConversation as? OneToOneChat }
            .filter { filter.matches($0, viewModel: self) }

        hiddenConversations = conversations
            .map { $0.baseConversation }
            .filter { $0.isHidden ?? false && filter.matches($0, viewModel: self) }
    }

    /// Reset filter to all if there are no more matches
    private func updateFilter() {
        // Turn off filter if no matches exist
        if filter != .all && filter != .unresolved && !conversations.contains(where: { conversation in
            filter.matches(conversation.baseConversation, viewModel: self)
        }) {
            filter = .all
        }
    }

    func loadUnresolvedChannels() async {
        showUnresolvedLoadingIndicator = true
        let service = MessagesServiceFactory.shared
        let courseWideChannelIds = conversations
            .compactMap { $0.baseConversation as? Channel }
            .filter { !($0.isAnnouncementChannel ?? false) && $0.isCourseWide ?? false }
            .map { $0.id }

        let response = await service.getUnresolvedChannelIds(for: parentViewModel.courseId, and: courseWideChannelIds)
        showUnresolvedLoadingIndicator = false
        switch response {
        case .done(let ids):
            unresolvedIds = ids
            withAnimation {
                allChannelsResolved = unresolvedIds.isEmpty
                updateConversations()
            }
        default:
            // In case of error, we can't display anything meaningful
            filter = .all
        }
    }
}

enum ConversationFilter: FilterPicker {

    case all, unread, recent, unresolved

    var displayName: String {
        return switch self {
        case .all:
            R.string.localizable.allFilter()
        case .unread:
            R.string.localizable.unreadFilter()
        case .recent:
            R.string.localizable.recentFilter()
        case .unresolved:
            R.string.localizable.unresolvedFilter()
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
        case .unresolved:
            "questionmark.circle"
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
        case .unresolved:
            Color.green
        }
    }

    var id: Int {
        hashValue
    }

    @MainActor
    func matches(_ conversation: BaseConversation, viewModel: ConversationListViewModel) -> Bool {
        switch self {
        case .all:
            true
        case .unread:
            conversation.unreadMessagesCount ?? 0 > 0
        case .recent:
            isRecent(channel: conversation, course: viewModel.parentViewModel.course)
        case .unresolved:
            viewModel.unresolvedIds.contains(conversation.id)
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
