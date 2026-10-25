//
//  MessageCell+URLHandler.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 24.12.24.
//

import Common
import DesignLibrary
import Foundation
import Faq
import Navigation
import SharedModels
import SwiftUI
import UserStore

@MainActor
struct MessageURLAction {
    private let conversationViewModel: ConversationViewModel
    private let cellViewModel: MessageCellModel
    private let navigationController: NavigationController
    private let tabs: CourseAvailableTabsDTO

    init(conversationViewModel: ConversationViewModel,
         cellViewModel: MessageCellModel,
         navigationController: NavigationController,
         tabs: CourseAvailableTabsDTO) {
        self.conversationViewModel = conversationViewModel
        self.cellViewModel = cellViewModel
        self.navigationController = navigationController
        self.tabs = tabs
    }

    func handle(url: URL) -> OpenURLAction.Result {
        if let mention = MentionScheme(url) {
            let coursePath = CoursePath(course: conversationViewModel.course, tabs: tabs)
            switch mention {
            case let .attachment(id, lectureId):
                navigationController.outerPath.append(LecturePath(id: lectureId, coursePath: coursePath, target: .init(attachmentId: Int(id), attachmentFilename: Int(id) == nil ? id : nil)))
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
            case let .slideId(id):
                handleSlideReference(slideId: id, unitId: nil, number: nil, coursePath: coursePath)
            case let .slide(number, attachmentUnit):
                handleSlideReference(slideId: nil, unitId: Int64(attachmentUnit), number: number, coursePath: coursePath)
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
        let lookup = makeLectureLookup(coursePath: coursePath)
        Task { await lookup.openUnit(Int64(attachmentUnit)) }
    }

    func makeLectureLookup(coursePath: CoursePath) -> LectureReferenceLookup {
        let navigation = navigationController
        let session = UserSessionFactory.shared
        let account = session.user?.login ?? session.username
        let server = session.institution?.baseURL
        let token = session.getToken()
        cellViewModel.lectureReferenceLookup?.cancel()
        let lookup = LectureReferenceLookup(coursePath: coursePath, loader: {
            await LectureServiceFactory.shared.getLecturesWithSlides(courseId: coursePath.id)
        }, navigate: { path in
            navigation.outerPath.append(path)
        }, openLectures: {
            navigation.goToCourse(id: coursePath.id)
            navigation.outerPath = NavigationPath()
            navigation.tabPath = NavigationPath()
            navigation.selectedPath = nil
            navigation.courseTab = .lecture
        }, isCurrent: {
            session.isLoggedIn && account == (session.user?.login ?? session.username) &&
                server == session.institution?.baseURL && token == session.getToken()
        })
        cellViewModel.lectureReferenceLookup = lookup
        return lookup
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

    func handleSlideReference(slideId: Int?, unitId: Int64?, number: Int?, coursePath: CoursePath) {
        let lookup = makeLectureLookup(coursePath: coursePath)
        Task { await lookup.openSlide(id: slideId, unit: unitId, number: number) }
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
    @Environment(\.availableTabs) private var tabs
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
                                                navigationController: navigationController,
                                                tabs: tabs)))
            .overlay(alignment: .topTrailing) {
                if cellViewModel.lectureReferenceLookup?.loading == true {
                    ProgressView().accessibilityLabel("Opening lecture")
                }
            }
            .onDisappear { cellViewModel.lectureReferenceLookup?.cancel() }
            .alert("Lecture could not be opened", isPresented: Binding(
                get: { cellViewModel.lectureReferenceLookup?.failure != nil },
                set: { if !$0 { cellViewModel.lectureReferenceLookup?.failure = nil } }
            )) {
                Button("Retry") {
                    if let lookup = cellViewModel.lectureReferenceLookup { Task { await lookup.retry() } }
                }
                Button("Open lectures") { cellViewModel.lectureReferenceLookup?.showLectures() }
                Button("Cancel", role: .cancel) { cellViewModel.lectureReferenceLookup?.failure = nil }
            } message: {
                Text(cellViewModel.lectureReferenceLookup?.failure?.message ?? "")
            }
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
