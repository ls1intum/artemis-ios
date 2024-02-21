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

    private let courseService: CourseService

    init(
        course: Course,
        conversation: Conversation,
        courseService: CourseService = CourseServiceFactory.shared
    ) {
        self.course = course
        self.conversation = conversation
        self.courseService = courseService
    }

    func search(loginOrName: String) async {
        isLoading = true
        members = await courseService.getCourseMembers(courseId: course.id, searchLoginOrName: loginOrName)
        isLoading = false
    }
}
