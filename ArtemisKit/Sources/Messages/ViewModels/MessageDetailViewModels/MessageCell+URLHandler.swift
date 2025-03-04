//
//  MessageCell+URLHandler.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 24.12.24.
//

import DesignLibrary
import Foundation
import Faq
import Navigation
import SwiftUI
import UserStore

@MainActor
struct MessageURLAction {
    private let conversationViewModel: ConversationViewModel
    private let cellViewModel: MessageCellModel
    private let navigationController: NavigationController

    init(conversationViewModel: ConversationViewModel,
         cellViewModel: MessageCellModel,
         navigationController: NavigationController) {
        self.conversationViewModel = conversationViewModel
        self.cellViewModel = cellViewModel
        self.navigationController = navigationController
    }

    func handle(url: URL) -> OpenURLAction.Result {
        if let mention = MentionScheme(url) {
            let coursePath = CoursePath(course: conversationViewModel.course)
            switch mention {
            case let .attachment(id, lectureId):
                navigationController.outerPath.append(LecturePath(id: lectureId, coursePath: coursePath))
            case let .channel(id):
                navigationController.tabPath.append(ConversationPath(id: id, coursePath: coursePath))
            case let .exercise(id):
                navigationController.outerPath.append(ExercisePath(id: id, coursePath: coursePath))
            case let .lecture(id):
                navigationController.outerPath.append(LecturePath(id: id, coursePath: coursePath))
            case let .lectureUnit(id, attachmentUnit):
                handleLectureUnit(id: id, attachmentUnit: attachmentUnit, coursePath: coursePath)
            case let .member(login):
                handleMember(login: login, coursePath: coursePath)
            case let .message(id):
                handleMessage(id: id, coursePath: coursePath)
            case let .slide(number, attachmentUnit):
                handleSlide(number: number, attachmentUnit: attachmentUnit, coursePath: coursePath)
            case let .faq(id):
                navigationController.tabPath.append(FaqPath(id: id, courseId: conversationViewModel.course.id))
            }
            return .handled
        }
        if url.isFileURL {
            cellViewModel.presentingAttachmentURL = url
            return .handled
        }
        return .systemAction
    }
}

// MARK: Handle Mentions
private extension MessageURLAction {
    func handleLectureUnit(id: String, attachmentUnit: Int, coursePath: CoursePath) {
        Task {
            let delegate = SendMessageLecturePickerViewModel(course: conversationViewModel.course)

            await delegate.loadLecturesWithSlides()

            if let lecture = delegate.firstLectureContains(attachmentUnit: attachmentUnit) {
                navigationController.outerPath.append(LecturePath(id: lecture.id, coursePath: coursePath))
                return
            }
        }
    }

    func handleMember(login: String, coursePath: CoursePath) {
        Task {
            if let conversation = await cellViewModel.getOneToOneChatOrCreate(login: login) {
                navigationController.goToCourseConversation(courseId: coursePath.id, conversation: conversation)
            }
        }
    }

    func handleMessage(id: Int64, coursePath: CoursePath) {
        guard let index = conversationViewModel.messages.firstIndex(of: .of(id: id)),
              let messagePath = MessagePath(
                message: Binding.constant(.done(response: conversationViewModel.messages[index].rawValue)),
                conversationPath: ConversationPath(conversation: conversationViewModel.conversation, coursePath: coursePath),
                conversationViewModel: conversationViewModel) else {
            return
        }

        navigationController.tabPath.append(messagePath)
    }

    func handleSlide(number: Int, attachmentUnit: Int, coursePath: CoursePath) {
        Task {
            let delegate = SendMessageLecturePickerViewModel(course: conversationViewModel.course)

            await delegate.loadLecturesWithSlides()

            if let lecture = delegate.firstLectureContains(attachmentUnit: attachmentUnit) {
                navigationController.outerPath.append(LecturePath(id: lecture.id, coursePath: coursePath))
                return
            }
        }
    }
}

private extension URL {
    var isFileURL: Bool {
        scheme == "https" &&
        host() == UserSessionFactory.shared.institution?.baseURL?.host() &&
        relativePath.starts(with: "/api/core/files/")
    }
}

extension OpenURLAction {
    init(_ messageURLAction: MessageURLAction) {
        self.init(handler: messageURLAction.handle)
    }
}

// MARK: ViewModifier

private struct MessageURLHandlerViewModifier: ViewModifier {
    @EnvironmentObject var navigationController: NavigationController
    let conversationViewModel: ConversationViewModel
    let cellViewModel: MessageCellModel

    init(conversationViewModel: ConversationViewModel,
         cellViewModel: MessageCellModel) {
        self.conversationViewModel = conversationViewModel
        self.cellViewModel = cellViewModel
    }

    func body(content: Content) -> some View {
        content
            .environment(\.openURL, .init(.init(conversationViewModel: conversationViewModel,
                                                cellViewModel: cellViewModel,
                                                navigationController: navigationController)))
            .sheet(isPresented: Binding(
                get: {
                    cellViewModel.presentingAttachmentURL != nil
                }, set: { newValue in
                    if !newValue {
                        cellViewModel.presentingAttachmentURL = nil
                    }
                }
            )) {
                if let url = cellViewModel.presentingAttachmentURL {
                    MessageAttachmentSheet(url: url)
                }
            }
    }
}

extension View {
    func messageUrlHandler(conversationViewModel: ConversationViewModel,
                           cellViewModel: MessageCellModel) -> some View {
        modifier(MessageURLHandlerViewModifier(conversationViewModel: conversationViewModel,
                                               cellViewModel: cellViewModel))
    }
}
