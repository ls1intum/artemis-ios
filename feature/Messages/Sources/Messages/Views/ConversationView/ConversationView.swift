//
//  ConversationView.swift
//  
//
//  Created by Sven Andabaka on 05.04.23.
//

import SwiftUI
import SharedModels
import DesignLibrary
import Navigation
import Common
import ArtemisMarkdown

// swiftlint:disable:next identifier_name
private let MAX_MINUTES_FOR_GROUPING_MESSAGES = 5

public struct ConversationView: View {

    @EnvironmentObject var navigationController: NavigationController

    @StateObject private var viewModel: ConversationViewModel

    @State private var showConversationInfoSheet = false

    public init(course: Course, conversation: Conversation) {
        _viewModel = StateObject(wrappedValue: ConversationViewModel(course: course, conversation: conversation))
    }

    public init(courseId: Int, conversationId: Int64) {
        _viewModel = StateObject(wrappedValue: ConversationViewModel(courseId: courseId, conversationId: conversationId))
    }

    private var conversationPath: ConversationPath {
        if let conversation = viewModel.conversation.value {
            return ConversationPath(conversation: conversation, coursePath: CoursePath(id: viewModel.courseId))
        }
        return ConversationPath(id: viewModel.conversationId, coursePath: CoursePath(id: viewModel.courseId))
    }

    private var isAllowedToPost: Bool {
        guard let channel = viewModel.conversation.value?.baseConversation as? Channel else { return true }
        // Channel is archived
        if channel.isArchived ?? false {
            return false
        }
        // Channel is announcement channel and current user is not instructor
        if channel.isAnnouncementChannel ?? false && !(channel.hasChannelModerationRights ?? false) {
            return false
        }
        return true
    }

    public var body: some View {
        VStack {
            ScrollViewReader { value in
                ScrollView {
                    PullToRefresh(coordinateSpaceName: "pullToRefresh") {
                        await viewModel.loadFurtherMessages()
                    }
                    VStack(alignment: .leading) {
                        DataStateView(data: $viewModel.dailyMessages,
                                      retryHandler: { await viewModel.loadMessages() }) { dailyMessages in
                            if dailyMessages.isEmpty {
                                Text(R.string.localizable.noMessagesYet())
                                    .padding(.vertical, .xl)
                                    .padding(.horizontal, .l)
                            } else {
                                ForEach(dailyMessages.sorted(by: { $0.key < $1.key }), id: \.key) { dailyMessage in
                                    ConversationDaySection(viewModel: viewModel,
                                                           day: dailyMessage.key,
                                                           messages: dailyMessage.value,
                                                           conversationPath: conversationPath)
                                }
                                Spacer()
                                    .id("bottom")
                            }
                        }
                    }
                }
                    .coordinateSpace(name: "pullToRefresh")
                    .onChange(of: viewModel.dailyMessages.value) {
                        // TODO: does not work correctly when loadFurtherMessages is called -> is called to early -> investigate
                        if let id = viewModel.shouldScrollToId {
                            withAnimation {
                                value.scrollTo(id, anchor: .bottom)
                            }
                        }
                    }
            }
            if isAllowedToPost {
                SendMessageView(viewModel: viewModel, sendMessageType: .message)
            }
        }
            .toolbar {
                ToolbarItem(placement: .principal) {
                    Button(action: {
                        showConversationInfoSheet = true
                    }, label: {
                        Text(viewModel.conversation.value?.baseConversation.conversationName ?? R.string.localizable.loading())
                            .foregroundColor(.Artemis.primaryLabel)
                            .frame(width: UIScreen.main.bounds.size.width * 0.6)
                    })
                }
            }
            .sheet(isPresented: $showConversationInfoSheet) {
                if let course = viewModel.course.value {
                    ConversationInfoSheetView(conversation: $viewModel.conversation,
                                              course: course,
                                              conversationId: viewModel.conversationId)
                } else {
                    Text(R.string.localizable.loading())
                }
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
            .task {
                for await notification in NotificationCenter.default.notifications(named: .ArtemisMarkdownViewDidTapURL) {
                    artemisMarkdownViewDidTapURL(notification: notification)
                }
            }
    }
}

private extension ConversationView {
    func artemisMarkdownViewDidTapURL(notification: Notification) {
        guard let url = notification.object as? URL else {
            return
        }

        if url.scheme == "artemis" {
            switch url.host {
            case "channel":
                do {
                    let id = try Int(url.pathComponents[1], format: .number)
                    navigationController.goToCourseConversation(courseId: viewModel.courseId, conversationId: Int64(id))
                } catch {
                    log.error(error)
                }
            case "exercise":
                do {
                    let id = try Int(url.pathComponents[1], format: .number)
                    navigationController.goToExercise(courseId: viewModel.courseId, exerciseId: id)
                } catch {
                    log.error(error)
                }
            case "lecture":
                do {
                    let id = try Int(url.pathComponents[1], format: .number)
                    navigationController.goToLecture(courseId: viewModel.courseId, lectureId: id)
                } catch {
                    log.error(error)
                }
            case "user":
                do {
                    let id = url.pathComponents[1]
                    // todo: user login to conversation id
                    // navigationController.goToCourseConversation(courseId: viewModel.courseId, conversationId: id)
                } catch {
                    log.error(error)
                }
            default:
                break
            }
        } else {
            UIApplication.shared.open(url)
        }
    }
}

private struct ConversationDaySection: View {

    @ObservedObject var viewModel: ConversationViewModel

    let day: Date
    let messages: [Message]
    let conversationPath: ConversationPath

    var body: some View {
        VStack(alignment: .leading) {
            Text(day, formatter: DateFormatter.dateOnly)
                .font(.headline)
                .padding(.top, .m)
                .padding(.horizontal, .l)
            Divider()
                .padding(.horizontal, .l)
            ForEach(Array(messages.enumerated()), id: \.1.id) { index, message in
                MessageCellWrapper(viewModel: viewModel,
                                   day: day,
                                   message: message,
                                   conversationPath: conversationPath,
                                   showHeader: (index == 0 ? true : shouldShowHeader(message: message, previousMessage: messages[index - 1])))
            }
        }
    }

    // header is not shown if same person messages multiple times within 5 minutes
    private func shouldShowHeader(message: Message, previousMessage: Message) -> Bool {
        !(message.author == previousMessage.author &&
          message.creationDate ?? .now < (previousMessage.creationDate ?? .yesterday).addingTimeInterval(TimeInterval(MAX_MINUTES_FOR_GROUPING_MESSAGES * 60)))
    }
}

private struct MessageCellWrapper: View {
    @ObservedObject var viewModel: ConversationViewModel

    let day: Date
    let message: Message
    let conversationPath: ConversationPath
    let showHeader: Bool

    private var messageBinding: Binding<DataState<BaseMessage>> {
        Binding(get: {
            if  let messageIndex = viewModel.dailyMessages.value?[day]?.firstIndex(where: { $0.id == message.id }),
                let message = viewModel.dailyMessages.value?[day]?[messageIndex] {
                return .done(response: message)
            }
            return .loading
        }, set: {
            if  let messageIndex = viewModel.dailyMessages.value?[day]?.firstIndex(where: { $0.id == message.id }),
                let newMessage = $0.value as? Message {
                viewModel.dailyMessages.value?[day]?[messageIndex] = newMessage
            }
        })
    }

    var body: some View {
        MessageCell(viewModel: viewModel,
                    message: messageBinding,
                    conversationPath: conversationPath,
                    showHeader: showHeader)
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
        }.padding(.top, -50)
    }
}
