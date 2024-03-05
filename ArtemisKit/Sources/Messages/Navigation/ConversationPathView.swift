//
//  ConversationPathView.swift
//
//
//  Created by Nityananda Zbil on 05.03.24.
//

import Common
import DesignLibrary
import Extensions
import Navigation
import SharedModels
import SharedServices
import SwiftUI

@Observable
final class CoursePathViewModel {
    let path: CoursePath
    var course: DataState<Course>

    private let courseService: CourseService

    init(path: CoursePath, courseService: CourseService = CourseServiceFactory.shared) {
        self.path = path
        self.course = path.course.map(DataState.done) ?? .loading

        self.courseService = courseService
    }

    func loadCourse() async {
        let result = await courseService.getCourse(courseId: path.id)
        self.course = result.map(\.course)
    }
}

struct CoursePathView<Content: View>: View {
    @State var viewModel: CoursePathViewModel
    @ViewBuilder let content: (Course) -> Content

    var body: some View {
        DataStateView(data: $viewModel.course) {
            await viewModel.loadCourse()
        } content: { course in
            content(course)
        }
        .task {
            await viewModel.loadCourse()
        }
    }
}

// MARK: - Conversation

@Observable
final class ConversationPathViewModel {
    let path: ConversationPath
    var conversation: DataState<Conversation>

    private let messagesService: MessagesService

    init(path: ConversationPath, messagesService: MessagesService = MessagesServiceFactory.shared) {
        self.path = path
        self.conversation = path.conversation.map(DataState.done) ?? .loading

        self.messagesService = messagesService
    }

    func loadConversation() async {
        let result = await messagesService.getConversations(for: path.coursePath.id)
        self.conversation = result.flatMap { response in
            if let conversation = response.first(where: { $0.id == path.id }) {
                return .success(conversation)
            } else {
                return .failure(UserFacingError(title: R.string.localizable.conversationNotLoaded()))
            }
        }
    }
}

public struct ConversationPathView<Content: View>: View {
    @State var viewModel: ConversationPathViewModel
    @ViewBuilder let content: (Course, Conversation) -> Content

    public var body: some View {
        DataStateView(data: $viewModel.conversation) {
            await viewModel.loadConversation()
        } content: { conversation in
            CoursePathView(viewModel: CoursePathViewModel(path: viewModel.path.coursePath)) { course in
                content(course, conversation)
            }
        }
        .task {
            await viewModel.loadConversation()
        }
    }
}

public extension ConversationPathView where Content == ConversationView {
    init(path: ConversationPath) {
        self.init(viewModel: ConversationPathViewModel(path: path), content: Content.init)
    }
}

// MARK: - Message

@Observable
final class MessagePathViewModel {
    let path: MessagePath
    var message: DataState<BaseMessage>

    init(path: MessagePath) {
        self.path = path
        self.message = path.message.wrappedValue
    }
}
