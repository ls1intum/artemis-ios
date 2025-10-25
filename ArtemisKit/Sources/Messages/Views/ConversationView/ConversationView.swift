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
                    description:
                        viewModel.filter.selectedFilter == "all" ?
                            Text(R.string.localizable.noMessagesDescription()) :
                            Text(R.string.localizable.noMatchingMessages())
                )
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
                                .id(viewModel.offlineMessages)
                            Spacer()
                                .id("bottom")
                        }
                    }
                    .coordinateSpace(name: "pullToRefresh")
                    .defaultScrollAnchor(.bottom)
                    .onChange(of: viewModel.messages, initial: true) {
                        #warning("does not work correctly when loadFurtherMessages is called -> is called to early")
                        if let id = viewModel.shouldScrollToId {
                            withAnimation {
                                value.scrollTo(id, anchor: .bottom)
                            }
                        }
                    }
                    .animation(.default, value: viewModel.selectedMessageId)
                    .onChange(of: viewModel.selectedMessageId) { _, newValue in
                        if let newValue {
                            // Make sure context menu is on screen
                            withAnimation {
                                value.scrollTo(newValue)
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
        .loadingIndicator(isLoading: $viewModel.isLoadingMessages)
        .toolbar {
            ToolbarItem(placement: .topBarLeading) {
                Button {
                    viewModel.isConversationInfoSheetPresented = true
                } label: {
                    HStack(alignment: .center, spacing: .m) {
                        viewModel.conversation.baseConversation.icon?
                            .scaledToFit()
                            .frame(height: 20)
                        VStack(alignment: .leading, spacing: .xxs) {
                            HStack(alignment: .center, spacing: .m) {
                                Text(viewModel.conversation.baseConversation.conversationName)
                                    .lineLimit(1)
                                    .fontWeight(.semibold)
                                    .frame(maxWidth: 155)
                                Image(systemName: "chevron.forward")
                                    .font(.caption2)
                                    .offset(x: -4, y: 1)
                            }
                            if let memberCount = viewModel.conversation.baseConversation.numberOfMembers,
                               !(viewModel.conversation.baseConversation is OneToOneChat) {
                                Text(R.string.localizable.numberOfMembers(memberCount))
                                    .font(.caption2)
                            }
                        }
                    }
                    .padding(.leading, .m)
                    .foregroundStyle(Color.Artemis.primaryLabel)
                }
            }
            ToolbarItem(placement: .topBarTrailing) {
                Menu {
                    Button {
                        viewModel.isConversationInfoSheetPresented = true
                    } label: {
                        Label(R.string.localizable.details(), systemImage: "info")
                    }
                    Picker(selection: $viewModel.filter.selectedFilter) {
                        Text(R.string.localizable.allFilter())
                            .tag("all")
                        ForEach(viewModel.filter.filters, id: \.self) { filter in
                            Text(filter.displayName)
                                .tag(filter.name)
                        }
                    } label: {
                        Label(R.string.localizable.filterMessages(),
                              systemImage: "line.3.horizontal.decrease")
                    }
                    .pickerStyle(.menu)
                } label: {
                    Image(systemName: "ellipsis.circle")
                }
            }
        }
        .sheet(isPresented: $viewModel.isConversationInfoSheetPresented) {
            ConversationInfoSheetView(course: viewModel.course, conversation: $viewModel.conversation)
        }
        .onDisappear {
            if navigationController.courseTab != .communication && navigationController.tabPath.isEmpty {
                // only cancel task if we leave communication
                SocketConnectionHandler.shared.cancelSubscriptions()
            }
            viewModel.saveContext()
            Task {
                await viewModel.removeAssociatedNotifications()
            }
        }
        .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
        .navigationBarTitleDisplayMode(.inline)
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
