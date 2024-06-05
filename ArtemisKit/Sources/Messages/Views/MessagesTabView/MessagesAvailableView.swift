//
//  MessagesTabView.swift
//
//
//  Created by Sven Andabaka on 03.04.23.
//

import Common
import DesignLibrary
import Navigation
import SharedModels
import SwiftUI

public struct MessagesAvailableView: View {

    @StateObject private var viewModel: MessagesAvailableViewModel

    @Binding private var searchText: String

    @State private var isCodeOfConductPresented = false

    private var searchResults: [Conversation] {
        if searchText.isEmpty {
            return []
        }
        return (viewModel.allConversations.value ?? []).filter {
            $0.baseConversation.conversationName.lowercased().contains(searchText.lowercased())
        }
    }

    public init(course: Course, searchText: Binding<String>) {
        self._viewModel = StateObject(wrappedValue: MessagesAvailableViewModel(course: course))
        self._searchText = searchText
    }

    public var body: some View {
        List {
            if !searchText.isEmpty {
                if searchResults.isEmpty {
                    Text(R.string.localizable.noResultForSearch())
                        .padding(.l)
                        .listRowSeparator(.hidden)
                }
                ForEach(searchResults) { conversation in
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
            } else {
                Group {
                    MixedMessageSection(
                        viewModel: viewModel,
                        conversations: $viewModel.favoriteConversations,
                        sectionTitle: R.string.localizable.favoritesSection())
                    MessageSection(
                        viewModel: viewModel,
                        conversations: $viewModel.channels,
                        sectionTitle: R.string.localizable.channels(),
                        conversationType: .channel)
                    MessageSection(
                        viewModel: viewModel,
                        conversations: $viewModel.exercises,
                        sectionTitle: R.string.localizable.exercises(),
                        conversationType: .channel,
                        isExpanded: false)
                    MessageSection(
                        viewModel: viewModel,
                        conversations: $viewModel.lectures,
                        sectionTitle: R.string.localizable.lectures(),
                        conversationType: .channel,
                        isExpanded: false)
                    MessageSection(
                        viewModel: viewModel,
                        conversations: $viewModel.exams,
                        sectionTitle: R.string.localizable.exams(),
                        conversationType: .channel,
                        isExpanded: false)
                    MessageSection(
                        viewModel: viewModel,
                        conversations: $viewModel.groupChats,
                        sectionTitle: R.string.localizable.groupChats(),
                        conversationType: .groupChat)
                    MessageSection(
                        viewModel: viewModel,
                        conversations: $viewModel.oneToOneChats,
                        sectionTitle: R.string.localizable.directMessages(),
                        conversationType: .oneToOneChat)
                    MixedMessageSection(
                        viewModel: viewModel,
                        conversations: $viewModel.hiddenConversations,
                        sectionTitle: R.string.localizable.hiddenSection(),
                        isExpanded: false)
                }
                .listRowSeparator(.visible, edges: .top)
                .listRowInsets(EdgeInsets(top: .s, leading: .l, bottom: .s, trailing: .l))

                HStack {
                    Spacer()
                    Button {
                        isCodeOfConductPresented = true
                    } label: {
                        HStack {
                            Image(systemName: "info.circle")
                            Text(R.string.localizable.codeOfConduct())
                        }
                    }
                    Spacer()
                }
                .listRowSeparator(.hidden)
            }
        }
        .listStyle(.plain)
        .refreshable {
            await viewModel.loadConversations()
        }
        .task {
            await viewModel.loadConversations()
        }
        .task {
            await viewModel.subscribeToConversationMembershipTopic()
        }
        .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
        .loadingIndicator(isLoading: $viewModel.isLoading)
        .sheet(isPresented: $isCodeOfConductPresented) {
            NavigationStack {
                ScrollView {
                    CodeOfConductView(course: viewModel.course)
                }
                .contentMargins(.l, for: .scrollContent)
                .navigationTitle(R.string.localizable.codeOfConduct())
                .navigationBarTitleDisplayMode(.inline)
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button {
                            isCodeOfConductPresented = false
                        } label: {
                            Text(R.string.localizable.done())
                        }
                    }
                }
            }
        }
    }
}

private struct MixedMessageSection: View {

    @ObservedObject private var viewModel: MessagesAvailableViewModel

    @Binding private var conversations: DataState<[Conversation]>

    @State private var isExpanded = true

    private let sectionTitle: String

    init(
        viewModel: MessagesAvailableViewModel,
        conversations: Binding<DataState<[Conversation]>>,
        sectionTitle: String,
        isExpanded: Bool = true
    ) {
        self.viewModel = viewModel
        self._conversations = conversations
        self.sectionTitle = sectionTitle
        self._isExpanded = State(wrappedValue: isExpanded)
    }

    var sectionUnreadCount: Int {
        (conversations.value ?? []).reduce(0) {
            $0 + ($1.baseConversation.unreadMessagesCount ?? 0)
        }
    }

    var body: some View {
        DataStateView(data: $conversations) {
            await viewModel.loadConversations()
        } content: { conversations in
            if !conversations.isEmpty {
                DisclosureGroup(isExpanded: $isExpanded) {
                    ForEach(
                        conversations.filter { !($0.baseConversation.isMuted ?? false) }
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
                    ForEach(conversations.filter({ $0.baseConversation.isMuted ?? false })) { conversation in
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
                        viewModel: viewModel,
                        sectionTitle: sectionTitle,
                        sectionUnreadCount: sectionUnreadCount,
                        isUnreadCountVisible: !isExpanded,
                        conversationType: nil)
                }
            }
        }
    }
}

private struct SectionDisclosureLabel: View {

    @ObservedObject var viewModel: MessagesAvailableViewModel

    @State private var isCreateNewConversationPresented = false
    @State private var isNewConversationDialogPresented = false
    @State private var isBrowseChannelsPresented = false
    @State private var isCreateChannelPresented = false

    let sectionTitle: String
    let sectionUnreadCount: Int
    let isUnreadCountVisible: Bool

    let conversationType: ConversationType?

    var body: some View {
        HStack {
            Text(sectionTitle)
                .font(.headline)
            Spacer()
            if isUnreadCountVisible {
                Badge(count: sectionUnreadCount)
            }
            if let conversationType {
                Image(systemName: "plus.bubble")
                    .onTapGesture {
                        if conversationType == .channel {
                            if viewModel.course.isAtLeastTutorInCourse {
                                isNewConversationDialogPresented = true
                            } else {
                                isBrowseChannelsPresented = true
                            }
                        } else {
                            isCreateNewConversationPresented = true
                        }
                    }
            }
        }
        .sheet(isPresented: $isCreateNewConversationPresented) {
            CreateOrAddToChatView(courseId: viewModel.courseId, configuration: .createChat)
        }
        .sheet(isPresented: $isCreateChannelPresented) {
            Task {
                await viewModel.loadConversations()
            }
        } content: {
            CreateChannelView(courseId: viewModel.courseId)
        }
        .sheet(isPresented: $isBrowseChannelsPresented) {
            Task {
                await viewModel.loadConversations()
            }
        } content: {
            BrowseChannelsView(courseId: viewModel.courseId)
        }
        .confirmationDialog("", isPresented: $isNewConversationDialogPresented, titleVisibility: .hidden) {
            Button(R.string.localizable.browseChannels()) {
                isBrowseChannelsPresented = true
            }
            Button(R.string.localizable.createChannel()) {
                isCreateChannelPresented = true
            }
        }
    }
}

private struct MessageSection<T: BaseConversation>: View {

    @ObservedObject var viewModel: MessagesAvailableViewModel

    @Binding var conversations: DataState<[T]>

    @State private var isExpanded = true

    var sectionTitle: String
    var conversationType: ConversationType

    var sectionUnreadCount: Int {
        (conversations.value ?? []).reduce(0) {
            $0 + ($1.unreadMessagesCount ?? 0)
        }
    }

    init(
        viewModel: MessagesAvailableViewModel,
        conversations: Binding<DataState<[T]>>,
        sectionTitle: String,
        conversationType: ConversationType,
        isExpanded: Bool = true
    ) {
        self.viewModel = viewModel
        self._conversations = conversations
        self.sectionTitle = sectionTitle
        self.conversationType = conversationType
        self._isExpanded = State(wrappedValue: isExpanded)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            DataStateView(data: $conversations) {
                await viewModel.loadConversations()
            } content: { conversations in
                ForEach(
                    conversations.filter { !($0.isMuted ?? false) },
                    id: \.id
                ) { conversation in
                    ConversationRow(viewModel: viewModel, conversation: conversation)
                }
                ForEach(
                    conversations.filter { $0.isMuted ?? false },
                    id: \.id
                ) { conversation in
                    ConversationRow(viewModel: viewModel, conversation: conversation)
                }
            }
        } label: {
            SectionDisclosureLabel(
                viewModel: viewModel,
                sectionTitle: sectionTitle,
                sectionUnreadCount: sectionUnreadCount,
                isUnreadCountVisible: !isExpanded,
                conversationType: conversationType)
        }
    }
}
