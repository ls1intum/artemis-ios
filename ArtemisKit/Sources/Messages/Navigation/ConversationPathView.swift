//
//  ConversationPathView.swift
//
//
//  Created by Nityananda Zbil on 05.03.24.
//

import Common
import DesignLibrary
import Navigation
import SharedModels
import SharedServices
import SwiftUI

extension DataState {
    func map<U>(_ transform: (T) -> U) -> DataState<U> {
        .init(toOptionalResult()?.map(transform))
    }

    private init(_ optionalResult: Swift.Result<T, UserFacingError>?) {
        switch optionalResult {
        case let .success(success):
            self = .done(response: success)
        case let .failure(failure):
            self = .failure(error: failure)
        case nil:
            self = .loading
        }
    }

    private func toOptionalResult() -> Swift.Result<T, UserFacingError>? {
        switch self {
        case let .done(response: success):
            return .success(success)
        case let .failure(error: failure):
            return .failure(failure)
        case .loading:
            return nil
        }
    }
}

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

        switch result {
        case .loading:
            conversation = .loading
        case .failure(let error):
            conversation = .failure(error: error)
        case .done(let response):
            guard let conversation = response.first(where: { $0.id == path.id }) else {
                self.conversation = .failure(error: UserFacingError(title: R.string.localizable.conversationNotLoaded()))
                return
            }
            self.conversation = .done(response: conversation)
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
