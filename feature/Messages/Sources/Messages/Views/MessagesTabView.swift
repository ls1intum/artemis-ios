//
//  MessagesTabView.swift
//  
//
//  Created by Sven Andabaka on 03.04.23.
//

import SwiftUI
import DesignLibrary
import Common
import SharedModels
import Navigation

public struct MessagesTabView: View {

    @StateObject private var viewModel: MessagesTabViewModel

    @Binding private var searchText: String

    private var searchResults: [Conversation] {
        if searchText.isEmpty {
            return []
        }
        return (viewModel.allConversations.value ?? []).filter { $0.baseConversation.conversationName.lowercased().contains(searchText.lowercased()) }
    }

    public init(searchText: Binding<String>, courseId: Int) {
        self._searchText = searchText
        self._viewModel = StateObject(wrappedValue: MessagesTabViewModel(courseId: courseId))
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
                }
                    .listRowSeparator(.visible, edges: .top)
                    .listRowInsets(EdgeInsets(top: .s, leading: .l, bottom: .s, trailing: .l))
            }
        }
            .listStyle(PlainListStyle())
            .refreshable {
                await viewModel.loadConversations()
            }
            .task {
                await viewModel.loadConversations()
            }
            .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
            .loadingIndicator(isLoading: $viewModel.isLoading)
    }
}

private struct MixedMessageSection: View {

    @ObservedObject private var viewModel: MessagesTabViewModel

    @Binding private var conversations: DataState<[Conversation]>

    @State private var isExpanded = true

    private let sectionTitle: String

    init(viewModel: MessagesTabViewModel,
         conversations: Binding<DataState<[Conversation]>>,
         sectionTitle: String,
         isExpanded: Bool = true) {
        self.viewModel = viewModel
        self._conversations = conversations
        self.sectionTitle = sectionTitle
        self._isExpanded = State(wrappedValue: isExpanded)
    }

    var sectionUnreadCount: Int {
        (conversations.value ?? []).reduce(0, { $0 + ($1.baseConversation.unreadMessagesCount ?? 0) })
    }

    var body: some View {
        DataStateView(data: $conversations,
                      retryHandler: { await viewModel.loadConversations() }) { conversations in
            if !conversations.isEmpty {
                DisclosureGroup(isExpanded: $isExpanded, content: {
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
                }, label: {
                    SectionDisclosureLabel(sectionTitle: sectionTitle, sectionUnreadCount: sectionUnreadCount, showUnreadCount: !isExpanded)
                })
            }
        }
    }
}

private struct SectionDisclosureLabel: View {
    let sectionTitle: String
    let sectionUnreadCount: Int
    let showUnreadCount: Bool

    var body: some View {
        HStack {
            Text(sectionTitle)
                .font(.headline)
            Spacer()
            if showUnreadCount {
                Badge(unreadCount: sectionUnreadCount)
            }
        }
    }
}

private struct MessageSection<T: BaseConversation>: View {

    @ObservedObject var viewModel: MessagesTabViewModel

    @Binding var conversations: DataState<[T]>

    @State private var isExpanded = true

    var sectionTitle: String
    var conversationType: ConversationType

    var sectionUnreadCount: Int {
        (conversations.value ?? []).reduce(0, { $0 + ($1.unreadMessagesCount ?? 0) })
    }

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded, content: {
            DataStateView(data: $conversations,
                          retryHandler: { await viewModel.loadConversations() }) { conversations in
                ForEach(conversations, id: \.id) { conversation in
                    ConversationRow(viewModel: viewModel, conversation: conversation)
                }
            }
        }, label: {
            SectionDisclosureLabel(sectionTitle: sectionTitle, sectionUnreadCount: sectionUnreadCount, showUnreadCount: !isExpanded)
        })
    }
}

private struct ConversationRow<T: BaseConversation>: View {

    @EnvironmentObject var navigationController: NavigationController

    @ObservedObject var viewModel: MessagesTabViewModel

    let conversation: T

    var body: some View {
        Button(action: {
            // should always be non-optional
            if let conversation = Conversation(conversation: conversation) {
                navigationController.path.append(ConversationPath(conversation: conversation, coursePath: CoursePath(id: viewModel.courseId)))
            }
        }, label: {
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
        })
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

private struct PlusActionDialog: ViewModifier {

    @Binding var isPresented: Bool

    @State private var showBrowseChannels = false
    @State private var showCreateChannel = false
    @State private var showCreateGroupChat = false
    @State private var showCreateOneToOneChat = false

    func body(content: Content) -> some View {
        content
            .confirmationDialog("", isPresented: $isPresented, titleVisibility: .hidden, actions: {
                Button(R.string.localizable.browseChannels()) {
                    showBrowseChannels = true
                }
                Button(R.string.localizable.createChannel()) {
                    showCreateChannel = true
                }
                Button(R.string.localizable.createGroupChat()) {
                    showCreateGroupChat = true
                }
                Button(R.string.localizable.createOneToOneChat()) {
                    showCreateOneToOneChat = true
                }
            })
            .sheet(isPresented: $showBrowseChannels) {
                Text("TODO Browse Channels")
            }
            .sheet(isPresented: $showCreateChannel) {
                Text("TODO Create Channel")
            }
            .sheet(isPresented: $showCreateGroupChat) {
                Text("TODO Create Group Chat")
            }
            .sheet(isPresented: $showCreateOneToOneChat) {
                Text("TODO Create oneToOne Chat")
            }
    }
}

public extension View {
    func plusActionDialog(isPresented: Binding<Bool>) -> some View {
        modifier(PlusActionDialog(isPresented: isPresented))
    }
}
