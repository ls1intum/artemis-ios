//
//  ConversationListView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 18.12.24.
//

import DesignLibrary
import SharedModels
import SwiftUI
import Navigation

struct ConversationListView: View {
    @State var viewModel: ConversationListViewModel
    @Binding var selectedConversation: ConversationPath?

    init(viewModel: MessagesAvailableViewModel,
         conversations: [Conversation],
         selectedConversation: Binding<ConversationPath?>) {
        _viewModel = State(initialValue: .init(parentViewModel: viewModel, conversations: conversations))
        _selectedConversation = selectedConversation
    }

    var body: some View {
        List(selection: $selectedConversation) {
            if !viewModel.searchText.isEmpty {
                if viewModel.searchResults.isEmpty {
                    ContentUnavailableView.search
                }
                ForEach(viewModel.searchResults) { conversation in
                    if let channel = conversation.baseConversation as? Channel {
                        ConversationRow(viewModel: viewModel.parentViewModel, conversation: channel)
                    }
                    if let groupChat = conversation.baseConversation as? GroupChat {
                        ConversationRow(viewModel: viewModel.parentViewModel, conversation: groupChat)
                    }
                    if let oneToOneChat = conversation.baseConversation as? OneToOneChat {
                        ConversationRow(viewModel: viewModel.parentViewModel, conversation: oneToOneChat)
                    }
                }.listRowBackground(Color.clear)
            } else {
                filterBar

                Group {
                    MixedMessageSection(
                        viewModel: viewModel.parentViewModel,
                        conversations: viewModel.favoriteConversations,
                        sectionTitle: R.string.localizable.favoritesSection(),
                        sectionIconName: "heart.fill")
                    MessageSection(
                        viewModel: viewModel,
                        conversations: viewModel.channels,
                        sectionTitle: R.string.localizable.generalTopics(),
                        sectionIconName: "bubble.left.fill")
                    MessageSection(
                        viewModel: viewModel,
                        conversations: viewModel.exercises,
                        sectionTitle: R.string.localizable.exercises(),
                        sectionIconName: "list.bullet",
                        isExpanded: false)
                    MessageSection(
                        viewModel: viewModel,
                        conversations: viewModel.lectures,
                        sectionTitle: R.string.localizable.lectures(),
                        sectionIconName: "doc.fill",
                        isExpanded: false)
                    MessageSection(
                        viewModel: viewModel,
                        conversations: viewModel.exams,
                        sectionTitle: R.string.localizable.exams(),
                        sectionIconName: "graduationcap.fill",
                        isExpanded: false)
                    if viewModel.parentViewModel.isDirectMessagingEnabled {
                        MessageSection(
                            viewModel: viewModel,
                            conversations: viewModel.groupChats,
                            sectionTitle: R.string.localizable.groupChats(),
                            sectionIconName: "bubble.left.and.bubble.right.fill")
                        MessageSection(
                            viewModel: viewModel,
                            conversations: viewModel.oneToOneChats,
                            sectionTitle: R.string.localizable.directMessages(),
                            sectionIconName: "bubble.left.fill")
                    }
                    MixedMessageSection(
                        viewModel: viewModel.parentViewModel,
                        conversations: viewModel.hiddenConversations,
                        sectionTitle: R.string.localizable.hiddenSection(),
                        sectionIconName: "nosign",
                        isExpanded: false)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: .s, bottom: 0, trailing: .s))

                HStack {
                    Spacer()
                    Button {
                        viewModel.parentViewModel.isCodeOfConductPresented = true
                    } label: {
                        HStack {
                            Image(systemName: "info.circle")
                            Text(R.string.localizable.codeOfConduct())
                        }
                    }
                    Spacer()
                }
                .listRowBackground(Color.clear)

                // Empty row so that there is always space for floating button
                Spacer()
                    .listRowBackground(Color.clear)
            }
        }
        .searchable(text: $viewModel.searchText)
        .overlay(alignment: .bottomTrailing) {
            CreateOrAddChannelButton(viewModel: viewModel.parentViewModel)
                .padding()
        }
    }

    @ViewBuilder var filterBar: some View {
        let nonNeededFilters = ConversationFilter.allCases.filter { filter in
            viewModel.parentViewModel.allConversations.value?.contains(where: { conversation in
                filter.matches(conversation.baseConversation, course: viewModel.parentViewModel.course)
            }) ?? false == false
        }
        if nonNeededFilters.count < 2 {
            FilterBarPicker(selectedFilter: $viewModel.filter.animation(),
                            hiddenFilters: nonNeededFilters)
        }
    }
}

private struct MixedMessageSection: View {

    @ObservedObject private var viewModel: MessagesAvailableViewModel

    private var conversations: [Conversation]

    @State private var isExpanded = true

    private let sectionTitle: String
    private let sectionIconName: String

    init(
        viewModel: MessagesAvailableViewModel,
        conversations: [Conversation],
        sectionTitle: String,
        sectionIconName: String,
        isExpanded: Bool = true
    ) {
        self.viewModel = viewModel
        self.conversations = conversations
        self.sectionTitle = sectionTitle
        self.sectionIconName = sectionIconName
        self._isExpanded = State(wrappedValue: isExpanded)
    }

    var sectionUnreadCount: Int {
        conversations.reduce(0) {
            $0 + ($1.baseConversation.unreadMessagesCount ?? 0)
        }
    }

    var body: some View {
        if !conversations.isEmpty {
            Section {
                DisclosureGroup(isExpanded: $isExpanded) {
                    ForEach(
                        conversations.sorted {
                            // Show non-muted conversations above muted ones
                            ($0.baseConversation.isMuted ?? false ? 0 : 1) > ($1.baseConversation.isMuted ?? false ? 0 : 1)
                        }
                    ) { conversation in
                        if let channel = conversation.baseConversation as? Channel {
                            ConversationRow(viewModel: viewModel, conversation: channel)
                        }
                        if let groupChat = conversation.baseConversation as? GroupChat {
                            ConversationRow(viewModel: viewModel, conversation: groupChat)
                        }
                        if let oneToOneChat = conversation.baseConversation as? OneToOneChat {
                            ConversationRow(viewModel: viewModel, conversation: oneToOneChat)
                        }
                    }
                } label: {
                    SectionDisclosureLabel(
                        sectionTitle: sectionTitle,
                        sectionIconName: sectionIconName,
                        sectionUnreadCount: sectionUnreadCount,
                        isUnreadCountVisible: !isExpanded)
                }
            }
        }
    }
}

private struct SectionDisclosureLabel: View {

    let sectionTitle: String
    let sectionIconName: String
    let sectionUnreadCount: Int
    let isUnreadCountVisible: Bool

    var body: some View {
        HStack {
            Label {
                Text(sectionTitle)
            } icon: {
                Image(systemName: sectionIconName)
                    .overlay(alignment: .top) {
                        if isUnreadCountVisible && sectionUnreadCount > 0 {
                            Circle()
                                .stroke(.background, lineWidth: .s)
                                .fill(Color.Artemis.artemisBlue)
                                .frame(width: .m * 1.5, height: .m * 1.5)
                                .frame(width: 30, alignment: .trailing)
                                .offset(x: .s, y: .s * -1)
                        }
                    }
            }
            Spacer()
            if isUnreadCountVisible && sectionUnreadCount > 0 {
                Text(sectionUnreadCount, format: .number.notation(.compactName))
                    .font(.body)
                    .foregroundStyle(.secondary)
            }
        }
        .font(.headline)
        .foregroundStyle(.primary)
        .padding(.vertical, .m)
    }
}

private struct MessageSection<T: BaseConversation>: View {

    var viewModel: ConversationListViewModel

    private var conversations: [T]

    @State private var isExpanded = true
    @State private var isFiltering = false

    let sectionTitle: String
    let sectionIconName: String

    var sectionUnreadCount: Int {
        conversations.reduce(0) {
            $0 + ($1.unreadMessagesCount ?? 0)
        }
    }

    init(
        viewModel: ConversationListViewModel,
        conversations: [T],
        sectionTitle: String,
        sectionIconName: String,
        isExpanded: Bool = true
    ) {
        self.viewModel = viewModel
        self.conversations = conversations
        self.sectionTitle = sectionTitle
        self.sectionIconName = sectionIconName
        self._isExpanded = State(wrappedValue: isExpanded)
    }

    var body: some View {
        if !conversations.isEmpty {
            Section {
                DisclosureGroup(isExpanded: Binding(get: {
                    isExpanded || isFiltering
                }, set: { newValue in
                    isExpanded = newValue
                    if !newValue {
                        isFiltering = false
                    }
                })) {
                    ForEach(
                        conversations.sorted {
                            // Show non-muted conversations above muted ones
                            ($0.isMuted ?? false ? 0 : 1) > ($1.isMuted ?? false ? 0 : 1)
                        },
                        id: \.id
                    ) { conversation in
                        ConversationRow(viewModel: viewModel.parentViewModel,
                                        conversation: conversation,
                                        namePrefix: namePrefix(of: conversation))
                    }
                } label: {
                    SectionDisclosureLabel(
                        sectionTitle: sectionTitle,
                        sectionIconName: sectionIconName,
                        sectionUnreadCount: sectionUnreadCount,
                        isUnreadCountVisible: !isExpanded && !isFiltering)
                }
                .onChange(of: viewModel.filter) {
                    isFiltering = viewModel.filter != .all
                }
            }
        }
    }

    /// Returns prefix used for channels of certain SubType if applicable
    func namePrefix(of conversation: T) -> String? {
        guard let channel = conversation as? Channel else { return nil }
        guard let subType = channel.subType?.rawValue else { return nil }
        return "\(subType)-"
    }
}
