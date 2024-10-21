//
//  ProfileViewModel.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 23.09.24.
//

import Common
import Foundation
import Navigation
import SharedModels
import SharedServices
import UserStore

@Observable
class ProfileViewModel {
    var error: UserFacingError?
    var isLoading = false
    var showProfileSheet = false

    let user: ConversationUser
    let role: UserRole?
    private var login: String?
    let course: Course
    var actions: [ProfileInfoSheetAction]

    init(course: Course, user: ConversationUser, role: UserRole?, actions: [ProfileInfoSheetAction]) {
        self.course = course
        self.user = user
        self.role = role
        self.actions = actions
    }

    // We can only create a conversation if we have the user's login
    // Don't allow sending messages to oneself
    var canSendMessage: Bool {
        (user.login != nil || login != nil)
        && UserSessionFactory.shared.user?.id != user.id
    }

    func loadUserLogin() async {
        guard let name = user.name else { return }
        isLoading = true
        let result = await CourseServiceFactory.shared.getCourseMembers(courseId: course.id, searchLoginOrName: name)
        switch result {
        case .done(let matches):
            login = matches.first(where: { $0.name == user.name })?.login
            isLoading = false
        default:
            // No user found – cannot send a message
            break
        }
    }

    @MainActor
    func openConversation(navigationController: NavigationController, completion: @escaping () -> Void) {
        guard let login = user.login ?? login else { return }
        isLoading = true
        Task {
            let messageCellModel = MessageCellModel(course: course, conversationPath: nil, isHeaderVisible: false, roundBottomCorners: false, retryButtonAction: {})
            if let conversation = await messageCellModel.getOneToOneChatOrCreate(login: login) {
                navigationController.goToCourseConversation(courseId: course.id, conversation: conversation)
                completion()
            }
            isLoading = false
        }
    }
}
