//
//  SendMessageMemberPickerModel.swift
//
//
//  Created by Nityananda Zbil on 28.10.23.
//

import Common
import SharedModels
import SharedServices
import SwiftUI

class SendMessageMemberPickerModel: BaseViewModel {

    let course: Course
    let conversation: Conversation

    @Published var members: DataState<[UserNameAndLoginDTO]> = .loading

    init(course: Course, conversation: Conversation) {
        self.course = course
        self.conversation = conversation
    }

    func search(loginOrName: String) async {
        isLoading = true
        members = await CourseServiceFactory.shared.getCourseMembers(courseId: course.id, searchLoginOrName: loginOrName)
        isLoading = false
    }
}
