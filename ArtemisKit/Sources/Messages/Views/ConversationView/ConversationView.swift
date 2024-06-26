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

    var dailyMessages: [(key: Date?, value: [Message])] {
        Dictionary(grouping: viewModel.messages, by: \.rawValue.creationDate?.startOfDay)
            .sorted {
                if let lhs = $0.key, let rhs = $1.key {
                    return lhs.compare(rhs) == .orderedAscending
                } else {
                    return false
                }
            }
            .map { key, messages in
                (key, messages.sortedByCreationDate())
            }
    }

    public var body: some View {
        VStack(spacing: 0) {
            if viewModel.messages.isEmpty && viewModel.offlineMessages.isEmpty {
                ContentUnavailableView(
                    R.string.localizable.noMessages(),
                    systemImage: "bubble.right",
                    description: Text(R.string.localizable.noMessagesDescription()))
            } else {
                ScrollViewReader { value in
                    ScrollView {
                        PullToRefresh(coordinateSpaceName: "pullToRefresh") {
                            await viewModel.loadEarlierMessages()
                        }
                        VStack(alignment: .leading) {
                            ForEach(dailyMessages, id: \.key) { dailyMessage in
                                if let day = dailyMessage.key {
                                    ConversationDaySection(viewModel: viewModel, day: day, messages: dailyMessage.value)
                                }
                            }
                            ConversationOfflineSection(viewModel)
                                // Force re-evaluation, when offline messages change.
                                .id(viewModel.offlineMessages.first)
                            Spacer()
                                .id("bottom")
                        }
                    }
                    .coordinateSpace(name: "pullToRefresh")
                    .onChange(of: viewModel.messages, initial: true) {
                        #warning("does not work correctly when loadFurtherMessages is called -> is called to early")
                        if let id = viewModel.shouldScrollToId {
                            withAnimation {
                                value.scrollTo(id, anchor: .bottom)
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
                    viewModel.isConversationInfoSheetPresented = true
                } label: {
                    Text(viewModel.conversation.baseConversation.conversationName)
                        .foregroundColor(.Artemis.primaryLabel)
                        .frame(width: UIScreen.main.bounds.size.width * 0.6)
                }
            }
        }
        .sheet(isPresented: $viewModel.isConversationInfoSheetPresented) {
            ConversationInfoSheetView(course: viewModel.course, conversation: $viewModel.conversation)
        }
        .task {
            viewModel.shouldScrollToId = "bottom"
            await viewModel.loadMessages()
        }
        .onDisappear {
            if navigationController.path.count < 2 {
                // only cancel task if we navigate back
                viewModel.subscription?.cancel()
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
