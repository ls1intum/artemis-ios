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

    let course: Course
    let courseId: Int

    @Published var codeOfConduct: DataState<String> = .loading
    @Published var codeOfConductAgreement: DataState<Bool> = .loading

    var isSearchable: Bool {
        if let codeOfConduct = course.courseInformationSharingMessagingCodeOfConduct, !codeOfConduct.isEmpty,
           let agreement = codeOfConductAgreement.value, agreement {
            return true
        } else {
            return false
        }
    }

    init(course: Course) {
        self.course = course
        self.courseId = course.id

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
            codeOfConduct.value.map { codeOfConduct in
                let agreement = CodeOfConductStorageServiceFactory.shared.getAgreement(for: courseId, codeOfConduct: codeOfConduct)
                codeOfConductAgreement = .done(response: agreement)
            }
        }
        isLoading = false
        // Handle error
        switch (codeOfConduct, codeOfConductAgreement) {
        case let (.failure(error), _), let (_, .failure(error)):
            presentError(userFacingError: error)
        default:
            break
        }
    }

    func acceptCodeOfConduct() async {
        guard let codeOfConduct = codeOfConduct.value else {
            return
        }
        isLoading = true
        let result: NetworkResponse
        if course.courseInformationSharingMessagingCodeOfConduct?.isEmpty ?? true {
            CodeOfConductStorageServiceFactory.shared.acceptCodeOfConduct(for: courseId, codeOfConduct: codeOfConduct)
            result = .success
        } else {
            result = await CodeOfConductServiceFactory.shared.acceptCodeOfConduct(for: courseId)
        }
        // Handle error
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
