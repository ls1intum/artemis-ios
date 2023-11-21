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
        return (viewModel.allConversations.value ?? []).filter { $0.baseConversation.conversationName.lowercased().contains(searchText.lowercased()) }
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
                    MixedMessageSection(viewModel: viewModel,
                                        conversations: $viewModel.favoriteConversations,
                                        sectionTitle: R.string.localizable.favoritesSection())
                    MessageSection(viewModel: viewModel,
                                   conversations: $viewModel.channels,
                                   sectionTitle: R.string.localizable.channels(),
                                   conversationType: .channel)
                    MessageSection(viewModel: viewModel,
                                   conversations: $viewModel.exercises,
                                   sectionTitle: R.string.localizable.exercises(),
                                   conversationType: .channel,
                                   isExpanded: false)
                    MessageSection(viewModel: viewModel,
                                   conversations: $viewModel.lectures,
                                   sectionTitle: R.string.localizable.lectures(),
                                   conversationType: .channel,
                                   isExpanded: false)
                    MessageSection(viewModel: viewModel,
                                   conversations: $viewModel.exams,
                                   sectionTitle: R.string.localizable.exams(),
                                   conversationType: .channel,
                                   isExpanded: false)
                    MessageSection(viewModel: viewModel,
                                   conversations: $viewModel.groupChats,
                                   sectionTitle: R.string.localizable.groupChats(),
                                   conversationType: .groupChat)
                    MessageSection(viewModel: viewModel,
                                   conversations: $viewModel.oneToOneChats,
                                   sectionTitle: R.string.localizable.directMessages(),
                                   conversationType: .oneToOneChat)
                    MixedMessageSection(viewModel: viewModel,
                                        conversations: $viewModel.hiddenConversations,
                                        sectionTitle: R.string.localizable.hiddenSection(),
                                        isExpanded: false)
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
                }
                .listRowSeparator(.visible, edges: .top)
                .listRowInsets(EdgeInsets(top: .s, leading: .l, bottom: .s, trailing: .l))
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
                .padding()
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

    init(viewModel: MessagesAvailableViewModel,
         conversations: Binding<DataState<[Conversation]>>,
         sectionTitle: String,
         isExpanded: Bool = true) {
        self.viewModel = viewModel
        self._conversations = conversations
        self.sectionTitle = sectionTitle
        self._isExpanded = State(wrappedValue: isExpanded)
    }

    var sectionUnreadCount: Int {
        (conversations.value ?? []).reduce(0) { $0 + ($1.baseConversation.unreadMessagesCount ?? 0) }
    }

    var body: some View {
        DataStateView(data: $conversations,
                      retryHandler: { await viewModel.loadConversations() }) { conversations in
            if !conversations.isEmpty {
                DisclosureGroup(isExpanded: $isExpanded) {
                    ForEach(conversations) { conversation in
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
                    SectionDisclosureLabel(viewModel: viewModel,
                                           sectionTitle: sectionTitle,
                                           sectionUnreadCount: sectionUnreadCount,
                                           showUnreadCount: !isExpanded,
                                           conversationType: nil)
                }
            }
        }
    }
}

private struct SectionDisclosureLabel: View {

    @ObservedObject var viewModel: MessagesAvailableViewModel

    @State private var showNewConversationSheet = false
    @State private var showNewConversationActionDialog = false
    @State private var showBrowseChannels = false
    @State private var showCreateChannel = false

    let sectionTitle: String
    let sectionUnreadCount: Int
    let showUnreadCount: Bool

    let conversationType: ConversationType?

    var body: some View {
        HStack {
            Text(sectionTitle)
                .font(.headline)
            Spacer()
            if let conversationType {
                Image(systemName: "plus.bubble")
                    .onTapGesture {
                        if conversationType == .channel {
                            if viewModel.course.isAtLeastTutorInCourse {
                                showNewConversationActionDialog = true
                            } else {
                                showBrowseChannels = true
                            }
                        } else {
                            showNewConversationSheet = true
                        }
                    }
            }
            if showUnreadCount {
                Badge(unreadCount: sectionUnreadCount)
            }
        }
        .sheet(isPresented: $showNewConversationSheet) {
            CreateOrAddToChatView(courseId: viewModel.courseId)
        }
        .sheet(isPresented: $showCreateChannel) {
            Task {
                await viewModel.loadConversations()
            }
        } content: {
            CreateChannelView(courseId: viewModel.courseId)
        }
        .sheet(isPresented: $showBrowseChannels) {
            Task {
                await viewModel.loadConversations()
            }
        } content: {
            BrowseChannelsView(courseId: viewModel.courseId)
        }
        .confirmationDialog("", isPresented: $showNewConversationActionDialog, titleVisibility: .hidden) {
            Button(R.string.localizable.browseChannels()) {
                showBrowseChannels = true
            }
            Button(R.string.localizable.createChannel()) {
                showCreateChannel = true
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
        (conversations.value ?? []).reduce(0) { $0 + ($1.unreadMessagesCount ?? 0) }
    }

    init(viewModel: MessagesAvailableViewModel,
         conversations: Binding<DataState<[T]>>,
         sectionTitle: String,
         conversationType: ConversationType,
         isExpanded: Bool = true) {
        self.viewModel = viewModel
        self._conversations = conversations
        self.sectionTitle = sectionTitle
        self.conversationType = conversationType
        self._isExpanded = State(wrappedValue: isExpanded)
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded) {
            DataStateView(data: $conversations,
                          retryHandler: { await viewModel.loadConversations() }) { conversations in
                ForEach(conversations, id: \.id) { conversation in
                    ConversationRow(viewModel: viewModel, conversation: conversation)
                }
            }
        } label: {
            SectionDisclosureLabel(viewModel: viewModel,
                                   sectionTitle: sectionTitle,
                                   sectionUnreadCount: sectionUnreadCount,
                                   showUnreadCount: !isExpanded,
                                   conversationType: conversationType)
        }
    }
}

private struct ConversationRow<T: BaseConversation>: View {

    @EnvironmentObject var navigationController: NavigationController

    @ObservedObject var viewModel: MessagesAvailableViewModel

    let conversation: T

    var body: some View {
        Button {
            // should always be non-optional
            if let conversation = Conversation(conversation: conversation) {
                navigationController.path.append(ConversationPath(conversation: conversation, coursePath: CoursePath(course: viewModel.course)))
            }
        } label: {
            HStack {
                if let icon = conversation.icon {
                    icon
                        .resizable()
                        .scaledToFit()
                        .frame(width: .extraSmallImage, height: .extraSmallImage)
                }
                Text(conversation.conversationName)
                Spacer()
                if let unreadCount = conversation.unreadMessagesCount {
                    Badge(unreadCount: unreadCount)
                }
            }
            .opacity((conversation.unreadMessagesCount ?? 0) > 0 ? 1 : 0.7)
            .contextMenu {
                contextMenuItems
            }
        }
        .listRowSeparator(.hidden)
    }

    var contextMenuItems: some View {
        Group {
            Button((conversation.isHidden ?? false) ? R.string.localizable.show() : R.string.localizable.hide()) {
                Task(priority: .userInitiated) {
                    await viewModel.hideUnhideConversation(conversationId: conversation.id, isHidden: !(conversation.isHidden ?? false))
                }
            }
            Button((conversation.isFavorite ?? false) ? R.string.localizable.unfavorite() : R.string.localizable.favorite()) {
                Task(priority: .userInitiated) {
                    await viewModel.setIsFavoriteConversation(conversationId: conversation.id, isFavorite: !(conversation.isFavorite ?? false))
                }
            }
        }
    }
}

private struct Badge: View {
    let unreadCount: Int

    var body: some View {
        if unreadCount > 0 {
            Text("\(unreadCount)")
                .foregroundColor(.white)
                .font(.headline)
                .padding(.m)
                .background(.red)
                .clipShape(Circle())
        } else {
            EmptyView()
        }
    }
}
