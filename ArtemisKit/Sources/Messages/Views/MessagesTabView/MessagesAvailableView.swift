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
                }.listRowBackground(Color.clear)
            } else {
                Group {
                    MixedMessageSection(
                        viewModel: viewModel,
                        conversations: $viewModel.favoriteConversations,
                        sectionTitle: R.string.localizable.favoritesSection(),
                        sectionIconName: "heart.fill")
                    MessageSection(
                        viewModel: viewModel,
                        conversations: $viewModel.channels,
                        sectionTitle: R.string.localizable.generalTopics(),
                        sectionIconName: "bubble.left.fill")
                    MessageSection(
                        viewModel: viewModel,
                        conversations: $viewModel.exercises,
                        sectionTitle: R.string.localizable.exercises(),
                        sectionIconName: "list.bullet",
                        isExpanded: false)
                    MessageSection(
                        viewModel: viewModel,
                        conversations: $viewModel.lectures,
                        sectionTitle: R.string.localizable.lectures(),
                        sectionIconName: "doc.fill",
                        isExpanded: false)
                    MessageSection(
                        viewModel: viewModel,
                        conversations: $viewModel.exams,
                        sectionTitle: R.string.localizable.exams(),
                        sectionIconName: "graduationcap.fill",
                        isExpanded: false)
                    MessageSection(
                        viewModel: viewModel,
                        conversations: $viewModel.groupChats,
                        sectionTitle: R.string.localizable.groupChats(),
                        sectionIconName: "bubble.left.and.bubble.right.fill")
                    MessageSection(
                        viewModel: viewModel,
                        conversations: $viewModel.oneToOneChats,
                        sectionTitle: R.string.localizable.directMessages(),
                        sectionIconName: "bubble.left.fill")
                    MixedMessageSection(
                        viewModel: viewModel,
                        conversations: $viewModel.hiddenConversations,
                        sectionTitle: R.string.localizable.hiddenSection(),
                        sectionIconName: "nosign",
                        isExpanded: false)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: .s, bottom: 0, trailing: .s))

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
                .listRowBackground(Color.clear)

                // Empty row so that there is always space for floating button
                Spacer()
                    .listRowBackground(Color.clear)
            }
        }
        .scrollContentBackground(.hidden)
        .listRowSpacing(0.01)
        .listSectionSpacing(.compact)
        .refreshable {
            await viewModel.loadConversations()
        }
        .task {
            await viewModel.loadConversations()
        }
        .task {
            await viewModel.subscribeToConversationMembershipTopic()
        }
        .overlay(alignment: .bottomTrailing) {
            CreateOrAddChannelButton(viewModel: viewModel)
                .padding()
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

private struct CreateOrAddChannelButton: View {
    @ObservedObject var viewModel: MessagesAvailableViewModel

    @State private var isCreateNewConversationPresented = false
    @State private var isNewConversationDialogPresented = false
    @State private var isBrowseChannelsPresented = false
    @State private var isCreateChannelPresented = false

    var body: some View {
        Menu {
            if viewModel.course.isAtLeastTutorInCourse {
                Button(R.string.localizable.createChannel(), systemImage: "plus.bubble.fill") {
                    isCreateChannelPresented = true
                }
            }
            Button(R.string.localizable.browseChannels(), systemImage: "number") {
                isBrowseChannelsPresented = true
            }
            if viewModel.course.courseInformationSharingConfiguration == .communicationAndMessaging {
                Button(R.string.localizable.createChat(), systemImage: "bubble.left.fill") {
                    isCreateNewConversationPresented = true
                }
            }
        } label: {
            Image(systemName: "plus.bubble")
                .foregroundStyle(.white)
                .font(.title2)
                .padding()
                .background(Color.Artemis.artemisBlue, in: .circle)
                .shadow(color: Color.gray.opacity(0.2), radius: .m)
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
    }
}

private struct MixedMessageSection: View {

    @ObservedObject private var viewModel: MessagesAvailableViewModel

    @Binding private var conversations: DataState<[Conversation]>

    @State private var isExpanded = true

    private let sectionTitle: String
    private let sectionIconName: String

    init(
        viewModel: MessagesAvailableViewModel,
        conversations: Binding<DataState<[Conversation]>>,
        sectionTitle: String,
        sectionIconName: String,
        isExpanded: Bool = true
    ) {
        self.viewModel = viewModel
        self._conversations = conversations
        self.sectionTitle = sectionTitle
        self.sectionIconName = sectionIconName
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
                            viewModel: viewModel,
                            sectionTitle: sectionTitle,
                            sectionIconName: sectionIconName,
                            sectionUnreadCount: sectionUnreadCount,
                            isUnreadCountVisible: !isExpanded)
                    }
                }
            }
        }
    }
}

private struct SectionDisclosureLabel: View {

    @ObservedObject var viewModel: MessagesAvailableViewModel

    let sectionTitle: String
    let sectionIconName: String
    let sectionUnreadCount: Int
    let isUnreadCountVisible: Bool

    var body: some View {
        HStack {
            Label(sectionTitle, systemImage: sectionIconName)
                .font(.headline)
                .foregroundStyle(.primary)
            Spacer()
            if isUnreadCountVisible {
                Badge(count: sectionUnreadCount)
            }
        }
        .padding(.vertical, .m)
    }
}

private struct MessageSection<T: BaseConversation>: View {

    @ObservedObject var viewModel: MessagesAvailableViewModel

    @Binding var conversations: DataState<[T]>

    @State private var isExpanded = true

    let sectionTitle: String
    let sectionIconName: String

    var sectionUnreadCount: Int {
        (conversations.value ?? []).reduce(0) {
            $0 + ($1.unreadMessagesCount ?? 0)
        }
    }

    init(
        viewModel: MessagesAvailableViewModel,
        conversations: Binding<DataState<[T]>>,
        sectionTitle: String,
        sectionIconName: String,
        isExpanded: Bool = true
    ) {
        self.viewModel = viewModel
        self._conversations = conversations
        self.sectionTitle = sectionTitle
        self.sectionIconName = sectionIconName
        self._isExpanded = State(wrappedValue: isExpanded)
    }

    var body: some View {
        Section {
            DisclosureGroup(isExpanded: $isExpanded) {
                DataStateView(data: $conversations) {
                    await viewModel.loadConversations()
                } content: { conversations in
                    ForEach(
                        conversations.sorted {
                            // Show non-muted conversations above muted ones
                            ($0.isMuted ?? false ? 0 : 1) > ($1.isMuted ?? false ? 0 : 1)
                        },
                        id: \.id
                    ) { conversation in
                        ConversationRow(viewModel: viewModel, conversation: conversation)
                    }
                }
            } label: {
                SectionDisclosureLabel(
                    viewModel: viewModel,
                    sectionTitle: sectionTitle,
                    sectionIconName: sectionIconName,
                    sectionUnreadCount: sectionUnreadCount,
                    isUnreadCountVisible: !isExpanded)
            }
        }
    }
}
