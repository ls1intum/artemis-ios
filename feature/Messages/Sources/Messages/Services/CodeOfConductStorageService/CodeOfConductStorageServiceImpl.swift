//
//  CodeOfConductStorageServiceImpl.swift
//  
//
//  Created by Nityananda Zbil on 26.10.23.
//

import Foundation
import UserStore

struct CodeOfConductStorageServiceImpl: CodeOfConductStorageService {

    func acceptCodeOfConduct(for courseId: Int, codeOfConduct: String) {
        guard let serverHost = UserSession.shared.institution?.baseURL?.absoluteString else {
            return
        }
        UserDefaults.standard.set(codeOfConduct.hashValue, forKey: "\(serverHost)|\(courseId)")
    }

    func getAgreement(for courseId: Int, codeOfConduct: String) -> Bool {
        guard let serverHost = UserSession.shared.institution?.baseURL?.absoluteString else {
            return false
        }
        return codeOfConduct.hashValue == UserDefaults.standard.integer(forKey: "\(serverHost)|\(courseId)")
    }
}
