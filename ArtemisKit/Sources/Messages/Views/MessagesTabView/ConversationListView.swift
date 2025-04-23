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
                    ConversationRow(viewModel: viewModel.parentViewModel, conversation: conversation.baseConversation)
                }.listRowBackground(Color.clear)
            } else {
                filterBar

                if viewModel.filter == .unresolved && viewModel.allChannelsResolved {
                    ContentUnavailableView(R.string.localizable.allDone(),
                                           image: "checkmark",
                                           description: Text(R.string.localizable.allDoneDescription()))
                }

                Group {
                    MessageSection(
                        viewModel: viewModel,
                        conversations: viewModel.favoriteConversations,
                        sectionTitle: R.string.localizable.favoritesSection(),
                        sectionIconName: "heart.fill",
                        hidePrefixes: false)
                    .environment(\.showFavoriteIcon, false)
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
                    MessageSection(
                        viewModel: viewModel,
                        conversations: viewModel.hiddenConversations,
                        sectionTitle: R.string.localizable.archivedSection(),
                        sectionIconName: "archivebox.fill",
                        isExpanded: false,
                        hidePrefixes: false)
                }
                .listRowBackground(Color.clear)
                .listRowInsets(EdgeInsets(top: 0, leading: .s, bottom: 0, trailing: .s))

                Section {
                    NavigationLink {
                        SavedMessagesContainerView(course: viewModel.parentViewModel.course)
                    } label: {
                        Label(R.string.localizable.savedMessages(), systemImage: "bookmark.fill")
                            .font(.headline)
                            .foregroundStyle(.primary)
                    }
                    .listRowInsets(EdgeInsets(top: 0, leading: .s, bottom: 0, trailing: .s))
                    .listRowBackground(Color.clear)
                }

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
        .task {
            if viewModel.filter == .unresolved {
                await viewModel.loadUnresolvedChannels()
            }
        }
        .loadingIndicator(isLoading: $viewModel.showUnresolvedLoadingIndicator)
        .searchable(text: $viewModel.searchText)
        .overlay(alignment: .bottomTrailing) {
            CreateOrAddChannelButton(viewModel: viewModel.parentViewModel)
                .padding()
        }
    }

    @ViewBuilder var filterBar: some View {
        let nonNeededFilters = ConversationFilter.allCases.filter { filter in
            viewModel.parentViewModel.allConversations.value?.contains(where: { conversation in
                filter.matches(conversation.baseConversation, viewModel: viewModel)
            }) ?? false == false
        }.filter {
            // Tutors should always see the unresolved filter
            if viewModel.parentViewModel.course.isAtLeastTutorInCourse && $0 == .unresolved {
                return false
            } else {
                return true
            }
        }
        if nonNeededFilters.count < ConversationFilter.allCases.count - 1 {
            FilterBarPicker(selectedFilter: $viewModel.filter.animation(),
                            hiddenFilters: nonNeededFilters)
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

private struct MessageSection: View {

    var viewModel: ConversationListViewModel

    private var conversations: [BaseConversation]

    @State private var isExpanded = true
    @State private var isFiltering = false

    let sectionTitle: String
    let sectionIconName: String
    let hidePrefixes: Bool

    var sectionUnreadCount: Int {
        conversations.reduce(0) {
            $0 + ($1.unreadMessagesCount ?? 0)
        }
    }

    init(
        viewModel: ConversationListViewModel,
        conversations: [BaseConversation],
        sectionTitle: String,
        sectionIconName: String,
        isExpanded: Bool = true,
        hidePrefixes: Bool = true
    ) {
        self.viewModel = viewModel
        self.conversations = conversations
        self.sectionTitle = sectionTitle
        self.sectionIconName = sectionIconName
        self._isExpanded = State(wrappedValue: isExpanded)
        self.hidePrefixes = hidePrefixes
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
    func namePrefix(of conversation: BaseConversation) -> String? {
        guard hidePrefixes,
              let channel = conversation as? Channel,
              let subType = channel.subType?.rawValue else {
            return nil
        }
        return "\(subType)-"
    }
}
