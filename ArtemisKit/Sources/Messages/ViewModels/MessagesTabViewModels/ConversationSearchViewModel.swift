//
//  ConversationSearchViewModel.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 11.11.25.
//

import Combine
import SharedModels
import SwiftUI

@Observable
class ConversationSearchViewModel {
    let conversationListViewModel: ConversationListViewModel

    var isLoading = false
    var limitConversations = true
    var limitMessages = true

    /// Search text to be used/modified by the view
    var searchText = "" {
        didSet {
            __searchText = searchText
        }
    }
    /// Debounced state for searchText
    private var debouncedSearchText = "" {
        didSet {
            Task {
                await loadMessages()
            }
        }
    }

    /// Helper variables for debouncing search text
    @ObservationIgnored @Published private var __searchText = "" // swiftlint:disable:this identifier_name
    @ObservationIgnored private var cancellables = Set<AnyCancellable>()

    @MainActor var noResults: Bool {
        conversations.isEmpty && !isLoading && messages.isEmpty
    }

    @MainActor var conversations: ArraySlice<Conversation> {
        conversationListViewModel.conversations.filter {
            $0.baseConversation.conversationName.localizedStandardContains(searchText)
        }
        .prefix(limitConversations ? 5 : .max)
    }
    var messages = [Message]()
    var limitedMessages: ArraySlice<Message> {
        messages.prefix(limitMessages ? 3 : .max)
    }

    init(conversationListViewModel: ConversationListViewModel) {
        self.conversationListViewModel = conversationListViewModel
        observeSearch()
    }
}

private extension ConversationSearchViewModel {
    func observeSearch() {
        $__searchText
            .debounce(for: 0.4, scheduler: DispatchQueue.main)
            .sink { [weak self] value in
                guard let self else { return }
                debouncedSearchText = value
            }
            .store(in: &cancellables)
    }

    func loadMessages() async {
        guard !debouncedSearchText.isEmpty else {
            messages = []
            return
        }

        isLoading = true
        defer {
            isLoading = false
        }

        let channelIds = await conversationListViewModel.conversations.map { $0.id }
        let service = MessagesServiceFactory.shared

        let result = await service.searchMessages(for: conversationListViewModel.parentViewModel.courseId,
                                                  channelIds: channelIds,
                                                  searchTerm: debouncedSearchText)
        switch result {
        case let .done(response: matches):
            self.messages = matches
        default:
            self.messages = []
        }
    }
}
