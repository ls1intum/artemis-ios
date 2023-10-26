//
//  CodeOfConductStorageServiceImpl.swift
//  
//
//  Created by TUM School on 26.10.23.
//

import Common
import Foundation
import SharedModels
import UserStore

struct CodeOfConductStorageServiceImpl: CodeOfConductStorageService {
    func getCodeOfConductAgreement(for course: Course) async -> DataState<Bool> {
        guard let serverHost = UserSession.shared.institution?.baseURL?.absoluteString else {
            return .failure(error: .init(title: "No base URL"))
        }
        let hashValue = course.courseInformationSharingMessagingCodeOfConduct?.hashValue
        let expected = UserDefaults.standard.integer(forKey: "\(serverHost)|\(course.id)")
        return .done(response: hashValue == expected)
    }

    func acceptCodeOfConduct(for course: Course) async -> NetworkResponse {
        guard let serverHost = UserSession.shared.institution?.baseURL?.absoluteString else {
            return .init(error: .invalidURL)
        }
        let hashValue = course.courseInformationSharingMessagingCodeOfConduct?.hashValue
        UserDefaults.standard.set(hashValue, forKey: "\(serverHost)|\(course.id)")
        return .success
    }
}
