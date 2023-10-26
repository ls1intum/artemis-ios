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

    func getCodeOfConductInformation() async {
        isLoading = true
        // Get code of conduct and agreement
        if let remoteCodeOfConduct = course.courseInformationSharingMessagingCodeOfConduct, !remoteCodeOfConduct.isEmpty {
            codeOfConduct = .done(response: remoteCodeOfConduct)
            codeOfConductAgreement = await CodeOfConductServiceFactory.shared.getAgreement(for: courseId)
        } else {
            codeOfConduct = await CodeOfConductServiceFactory.shared.getTemplate()
            switch codeOfConduct {
            case .loading:
                codeOfConductAgreement = .loading
            case .failure(let error):
                codeOfConductAgreement = .failure(error: error)
            case .done(let response):
                codeOfConductAgreement = .done(response: CodeOfConductStorageServiceFactory.shared.getAgreement(for: courseId, codeOfConduct: response))
            }
        }
        // Get code of conduct responsible users
        codeOfConductResonsibleUsers = await CodeOfConductServiceFactory.shared.getResponsibleUsers(for: courseId)
        isLoading = false
    }

    func acceptCodeOfConduct() async {
        isLoading = true
        let result: NetworkResponse
        if course.courseInformationSharingMessagingCodeOfConduct?.isEmpty ?? true {
            switch codeOfConduct {
            case .loading:
                result = .loading
            case .failure(let error):
                result = .failure(error: error)
            case .done(let response):
                CodeOfConductStorageServiceFactory.shared.acceptCodeOfConduct(for: courseId, codeOfConduct: response)
                result = .success
            }
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
