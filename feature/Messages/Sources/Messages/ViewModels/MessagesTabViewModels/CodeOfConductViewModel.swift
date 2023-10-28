//
//  CodeOfConductViewModel.swift
//
//
//  Created by Nityananda Zbil on 28.10.23.
//

import Common
import SharedModels
import SwiftUI

class CodeOfConductViewModel: BaseViewModel {

    let course: Course
    let courseId: Int

    @Published var codeOfConduct: DataState<String> = .loading
    @Published var responsibleUsers: DataState<[ResponsibleUserDTO]> = .loading

    init(course: Course) {
        self.course = course
        self.courseId = course.id

        super.init()
    }

    func getCodeOfConductInformation() async {
        isLoading = true
        // Get code of conduct
        if let remoteCodeOfConduct = course.courseInformationSharingMessagingCodeOfConduct, !remoteCodeOfConduct.isEmpty {
            codeOfConduct = .done(response: remoteCodeOfConduct)
        } else {
            codeOfConduct = await CodeOfConductServiceFactory.shared.getTemplate()
        }
        // Get code of conduct responsible users
        responsibleUsers = await CodeOfConductServiceFactory.shared.getResponsibleUsers(for: courseId)
        isLoading = false
    }
}
