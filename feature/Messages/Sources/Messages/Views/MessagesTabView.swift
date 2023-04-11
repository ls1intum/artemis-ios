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

    public init(courseId: Int) {
        self._viewModel = StateObject(wrappedValue: MessagesTabViewModel(courseId: courseId))
    }

    public var body: some View {
        List {
            Group {
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
                // TODO: show hidden sections
            }
                .listRowSeparator(.visible, edges: .top)
                .listRowInsets(EdgeInsets(top: .s, leading: .l, bottom: .s, trailing: .l))
        }
            .listStyle(PlainListStyle())
            .refreshable {
                await viewModel.loadConversations()
            }
            .task {
                await viewModel.loadConversations()
            }
    }
}

struct MessageSection<T: BaseConversation>: View {

    @EnvironmentObject var navigationController: NavigationController

    @ObservedObject var viewModel: MessagesTabViewModel

    @Binding var conversations: DataState<[T]>

    @State private var isExpanded = true

    var sectionTitle: String
    var conversationType: ConversationType

    var body: some View {
        DisclosureGroup(isExpanded: $isExpanded, content: {
            DataStateView(data: $conversations,
                          retryHandler: { await viewModel.loadConversations() }) { conversations in
                ForEach(conversations, id: \.id) { conversation in
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
                            if let unreadCount = conversation.unreadMessagesCount,
                               unreadCount > 0 {
                                Text("\(unreadCount)")
                                    .foregroundColor(.white)
                                    .font(.headline)
                                    .padding(.m)
                                    .background(.red)
                                    .clipShape(Circle())
                            }
                        }
                            .opacity((conversation.unreadMessagesCount ?? 0) > 0 ? 1 : 0.7)
                            .contextMenu {
                                contextMenuItems
                            }
                    })
                        .listRowSeparator(.hidden)
                }
            }
        }, label: {
            HStack {
                Text(sectionTitle)
                    .font(.headline)
                    .italic()
            }
        })
    }

    var contextMenuItems: some View {
        Group {
            Button(R.string.localizable.hide()) {
                print("TODO")
            }
            Button(R.string.localizable.favorite()) {
                print("TODO")
            }
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
