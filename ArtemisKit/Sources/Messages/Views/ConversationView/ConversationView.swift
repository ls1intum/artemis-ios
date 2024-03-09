//
//  ConversationView.swift
//  
//
//  Created by Sven Andabaka on 05.04.23.
//

import ArtemisMarkdown
import Common
import DesignLibrary
import Navigation
import SharedModels
import SwiftUI

public struct ConversationView: View {

    @EnvironmentObject var navigationController: NavigationController

    @StateObject var viewModel: ConversationViewModel

    @State private var isConversationInfoSheetPresented = false

    private var conversationPath: ConversationPath {
        ConversationPath(conversation: viewModel.conversation, coursePath: CoursePath(course: viewModel.course))
    }

    public var body: some View {
        VStack {
            DataStateView(data: $viewModel.dailyMessages) {
                await viewModel.loadMessages()
            } content: { dailyMessages in
                if dailyMessages.isEmpty {
                    ContentUnavailableView(
                        R.string.localizable.noMessages(),
                        systemImage: "bubble.right",
                        description: Text(R.string.localizable.noMessagesDescription()))
                } else {
                    ScrollViewReader { value in
                        ScrollView {
                            PullToRefresh(coordinateSpaceName: "pullToRefresh") {
                                await viewModel.loadFurtherMessages()
                            }
                            VStack(alignment: .leading) {
                                ForEach(dailyMessages.sorted(by: { $0.key < $1.key }), id: \.key) { dailyMessage in
                                    ConversationDaySection(
                                        viewModel: viewModel,
                                        day: dailyMessage.key,
                                        messages: dailyMessage.value,
                                        conversationPath: conversationPath)
                                }
                                if !viewModel.offlineMessages.isEmpty {
                                    VStack(alignment: .leading) {
                                        Text("Queue")
                                            .font(.headline)
                                            .padding(.top, .m)
                                            .padding(.horizontal, .l)
                                        Divider()
                                            .padding(.horizontal, .l)
                                    }
                                    ForEach(viewModel.offlineMessages) { offline in
                                        OfflineMessageCell(
                                            viewModel: OfflineMessageCellModel(
                                                course: viewModel.course,
                                                conversation: viewModel.conversation,
                                                message: offline,
                                                delegate: OfflineMessageCellModelDelegate(viewModel)),
                                            conversationViewModel: viewModel)
                                    }
                                }
                                Spacer()
                                    .id("bottom")
                            }
                        }
                        .coordinateSpace(name: "pullToRefresh")
                        .onChange(of: viewModel.dailyMessages.value, initial: true) {
                            // TODO: does not work correctly when loadFurtherMessages is called -> is called to early -> investigate
                            if let id = viewModel.shouldScrollToId {
                                withAnimation {
                                    value.scrollTo(id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
            }
            if viewModel.isAllowedToPost {
                SendMessageView(
                    viewModel: SendMessageViewModel(
                        course: viewModel.course,
                        conversation: viewModel.conversation,
                        configuration: .message,
                        delegate: SendMessageViewModelDelegate(viewModel)
                    )
                )
            }
        }
        .toolbar {
            ToolbarItem(placement: .principal) {
                Button {
                    isConversationInfoSheetPresented = true
                } label: {
                    Text(viewModel.conversation.baseConversation.conversationName)
                        .foregroundColor(.Artemis.primaryLabel)
                        .frame(width: UIScreen.main.bounds.size.width * 0.6)
                }
            }
        }
        .sheet(isPresented: $isConversationInfoSheetPresented) {
            #warning("Constant")
            ConversationInfoSheetView(
                conversation: .constant(.done(response: viewModel.conversation)),
                course: viewModel.course,
                conversationId: viewModel.conversation.id)
        }
        .task {
            viewModel.shouldScrollToId = "bottom"
            if viewModel.dailyMessages.value == nil {
                await viewModel.loadMessages()
            }
        }
        .onDisappear {
            if navigationController.path.count < 2 {
                // only cancel task if we navigate back
                viewModel.websocketSubscriptionTask?.cancel()
            }
        }
        .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
    }
}

extension ConversationView {
    init(course: Course, conversation: Conversation) {
        self.init(viewModel: ConversationViewModel(course: course, conversation: conversation))
    }
}

extension Date: Identifiable {
    public var id: Date {
        return self
    }
}

private struct PullToRefresh: View {

    var coordinateSpaceName: String
    var onRefresh: () async -> Void

    @State var needRefresh = false

    var body: some View {
        GeometryReader { geo in
            if geo.frame(in: .named(coordinateSpaceName)).midY > 50 {
                Spacer()
                    .onAppear {
                        needRefresh = true
                        Task {
                            await onRefresh()
                            needRefresh = false
                        }
                    }
            }
            HStack {
                Spacer()
                if needRefresh {
                    ProgressView()
                } else {
                    EmptyView()
                }
                Spacer()
            }
        }
        .padding(.top, -50)
    }
}

#Preview {
    ConversationView(
        viewModel: ConversationViewModel(
            course: MessagesServiceStub.course,
            conversation: MessagesServiceStub.conversation,
            messagesService: MessagesServiceStub())
    )
}
