//
//  MessagesTabViewModel.swift
//
//
//  Created by Nityananda Zbil on 26.10.23.
//

import APIClient
import Common
import Combine
import SharedModels

@MainActor
class MessagesTabViewModel: BaseViewModel {

    let courseId: Int
    let course: Course

    @Published var codeOfConduct: DataState<String> = .loading
    @Published var codeOfConductAgreement: DataState<Bool> = .loading
    @Published var codeOfConductResonsibleUsers: DataState<[ResponsibleUserDTO]> = .loading

    var isSearchable: Bool {
        if let codeOfConduct = course.courseInformationSharingMessagingCodeOfConduct, !codeOfConduct.isEmpty,
           let agreement = codeOfConductAgreement.value, agreement {
            return true
        } else {
            return false
        }
    }

    init(course: Course) {
        self.courseId = course.id
        self.course = course

        super.init()
    }

    func task() async {
        isLoading = true
        // Get code of conduct and agreement
        if let codeOfConduct = course.courseInformationSharingMessagingCodeOfConduct, !codeOfConduct.isEmpty {
            self.codeOfConduct = .done(response: codeOfConduct)
            self.codeOfConductAgreement = await CodeOfConductServiceFactory.shared.getCodeOfConductAgreement(for: courseId)
        } else {
            self.codeOfConduct = await CodeOfConductServiceFactory.shared.getCodeOfConductTemplate()
            self.codeOfConductAgreement = await CodeOfConductStorageServiceFactory.shared.getCodeOfConductAgreement(for: course)
        }
        // Get code of conduct agreement
        self.codeOfConductResonsibleUsers = await CodeOfConductServiceFactory.shared.getCodeOfConductResponsibleUsers(for: courseId)
        isLoading = false
    }

    func acceptCodeOfConduct() async {
        isLoading = true
        let result: NetworkResponse
        if course.courseInformationSharingMessagingCodeOfConduct?.isEmpty ?? true {
            result = await CodeOfConductStorageServiceFactory.shared.acceptCodeOfConduct(for: course)
        } else {
            result = await CodeOfConductServiceFactory.shared.acceptCodeOfConduct(for: courseId)
        }
        switch result {
        case .notStarted, .loading:
            isLoading = false
        case .success:
            codeOfConductAgreement = .done(response: true)
            isLoading = false
        case .failure(let error):
            isLoading = false
            if let apiClientError = error as? APIClientError {
                presentError(userFacingError: UserFacingError(error: apiClientError))
            } else {
                presentError(userFacingError: UserFacingError(title: error.localizedDescription))
            }
        }
    }
}
