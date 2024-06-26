//
//  CodeOfConductViewModel.swift
//
//
//  Created by Nityananda Zbil on 28.10.23.
//

import Common
import SharedModels
import SwiftUI

@MainActor
class CodeOfConductViewModel: BaseViewModel {

    let course: Course
    let courseId: Int

    @Published var codeOfConduct: DataState<String> = .loading
    @Published var responsibleUsers: DataState<[ResponsibleUserDTO]> = .loading

    init(course: Course) {
        self.course = course
        self.courseId = course.id

        if let courseCodeOfConduct = course.courseInformationSharingMessagingCodeOfConduct, !courseCodeOfConduct.isEmpty {
            codeOfConduct = .done(response: courseCodeOfConduct)
        }

        super.init()
    }

    func getCodeOfConductInformation() async {
        isLoading = true
        // Get code of conduct if not done
        if case .loading = codeOfConduct {
            codeOfConduct = await CodeOfConductServiceFactory.shared.getTemplate()
        }
        // Get responsible users
        responsibleUsers = await CodeOfConductServiceFactory.shared.getResponsibleUsers(for: courseId)
        isLoading = false
        // Handle error
        switch (codeOfConduct, responsibleUsers) {
        case let (.failure(error), _), let (_, .failure(error)):
            presentError(userFacingError: error)
        default:
            break
        }
    }
}
