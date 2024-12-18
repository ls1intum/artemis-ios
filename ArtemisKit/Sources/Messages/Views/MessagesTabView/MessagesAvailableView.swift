//
//  MessagesTabView.swift
//
//
//  Created by Sven Andabaka on 03.04.23.
//

import Common
import DesignLibrary
import Faq
import Navigation
import SharedModels
import SwiftUI

public struct MessagesAvailableView: View {

    @Environment(\.horizontalSizeClass) var sizeClass
    @EnvironmentObject var navController: NavigationController
    @StateObject private var viewModel: MessagesAvailableViewModel

    @State var columnVisibilty: NavigationSplitViewVisibility = .doubleColumn

    @State private var searchText = ""

    @State private var isCodeOfConductPresented = false

    private var searchResults: [Conversation] {
        if searchText.isEmpty && viewModel.filter == .all {
            return []
        }
        return (viewModel.allConversations.value ?? []).filter {
            $0.baseConversation.conversationName.lowercased().contains(searchText.lowercased())
        }
    }

    private var selectedConversation: Binding<ConversationPath?> {
        navController.selectedPathBinding($navController.selectedPath)
    }

    public init(course: Course) {
        self._viewModel = StateObject(wrappedValue: MessagesAvailableViewModel(course: course))
    }

    public var body: some View {
        NavigationSplitView(columnVisibility: $columnVisibilty) {
            List(selection: selectedConversation) {
                if !searchText.isEmpty {
                    if searchResults.isEmpty {
                        ContentUnavailableView.search
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
                    filterBar

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
                        MixedMessageSection(
                            viewModel: viewModel,
                            conversations: $viewModel.recents,
                            sectionTitle: R.string.localizable.recentsSection(),
                            sectionIconName: "clock.fill")
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
                        if viewModel.isDirectMessagingEnabled {
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
                        }
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
            .searchable(text: $searchText)
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
            .navigationTitle(viewModel.course.title ?? R.string.localizable.loading())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BackToRootButton(placement: .navBar, sizeClass: sizeClass)
                }
            }
        } detail: {
            NavigationStack(path: $navController.tabPath) {
                Group {
                    if let path = navController.selectedPath as? ConversationPath {
                        ConversationPathView(path: path)
                            .id(path.id)
                    } else {
                        SelectDetailView()
                    }
                }
                .modifier(NavigationDestinationMessagesModifier())
                .navigationDestination(for: FaqPath.self) { path in
                    FaqPathView(path: path)
                }
            }
        }
        // Add a file picker here, inside the navigation it doesn't work sometimes
        .supportsFilePicker()
    }

    @ViewBuilder var filterBar: some View {
        let nonNeededFilters = ConversationFilter.allCases.filter { filter in
            viewModel.allConversations.value?.contains(where: { conversation in
                filter.matches(conversation.baseConversation)
            }) ?? false == false
        }
        if nonNeededFilters.count < 2 {
            FilterBarPicker(selectedFilter: $viewModel.filter,
                            hiddenFilters: nonNeededFilters)
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

    @ObservedObject var viewModel: MessagesAvailableViewModel

    @Binding var conversations: DataState<[T]>

    @State private var isExpanded = true
    @State private var isFiltering = false

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
        DataStateView(data: $conversations) {
            await viewModel.loadConversations()
        } content: { conversations in
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
                            ConversationRow(viewModel: viewModel,
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
                }
            }
        }
        .onChange(of: viewModel.filter) {
            isFiltering = viewModel.filter != .all
        }
    }

    /// Returns prefix used for channels of certain SubType if applicable
    func namePrefix(of conversation: T) -> String? {
        guard let channel = conversation as? Channel else { return nil }
        guard let subType = channel.subType?.rawValue else { return nil }
        return "\(subType)-"
    }
}
