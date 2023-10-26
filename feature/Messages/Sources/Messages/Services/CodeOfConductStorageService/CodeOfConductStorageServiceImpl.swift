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
    func getAgreement(for courseId: Int, codeOfConduct: String) async -> DataState<Bool> {
        guard let serverHost = UserSession.shared.institution?.baseURL?.absoluteString else {
            return .failure(error: .init(error: .invalidURL))
        }
        let expected = UserDefaults.standard.integer(forKey: "\(serverHost)|\(courseId)")
        return .done(response: codeOfConduct.hashValue == expected)
    }

    func accept(for courseId: Int, codeOfConduct: String) async -> NetworkResponse {
        guard let serverHost = UserSession.shared.institution?.baseURL?.absoluteString else {
            return .init(error: .invalidURL)
        }
        UserDefaults.standard.set(codeOfConduct.hashValue, forKey: "\(serverHost)|\(courseId)")
        return .success
    }
}
