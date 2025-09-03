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
    let course: Course
    var actions: [ProfileInfoSheetAction]

    init(course: Course, user: ConversationUser, role: UserRole?, actions: [ProfileInfoSheetAction]) {
        self.course = course
        self.user = user
        self.role = role
        self.actions = actions
    }

    // Don't allow sending messages to oneself
    var canSendMessage: Bool {
        UserSessionFactory.shared.user?.id != user.id
    }

    @MainActor
    func openConversation(navigationController: NavigationController, completion: @escaping () -> Void) {
        isLoading = true
        Task {
            let messageCellModel = MessageCellModel(course: course, conversationPath: nil, isHeaderVisible: false, roundBottomCorners: false, retryButtonAction: {})
            if let conversation = await messageCellModel.getOneToOneChatOrCreate(userId: Int(user.id)) {
                navigationController.goToCourseConversation(courseId: course.id, conversation: conversation)
                completion()
            }
            isLoading = false
        }
    }
}
