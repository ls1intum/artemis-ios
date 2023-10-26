//
//  CodeOfConductStorageServiceImpl.swift
//  
//
//  Created by Nityananda Zbil on 26.10.23.
//

import CryptoKit
import Foundation
import UserStore

struct CodeOfConductStorageServiceImpl: CodeOfConductStorageService {

    func acceptCodeOfConduct(for courseId: Int, codeOfConduct: String) {
        guard let serverHost = UserSession.shared.institution?.baseURL?.absoluteString,
              let data = codeOfConduct.data(using: .utf8) else {
            return
        }
        let digest = Data(SHA256.hash(data: data))
        UserDefaults.standard.set(digest, forKey: "\(serverHost)|\(courseId)")
    }

    func getAgreement(for courseId: Int, codeOfConduct: String) -> Bool {
        guard let serverHost = UserSession.shared.institution?.baseURL?.absoluteString,
              let data = codeOfConduct.data(using: .utf8) else {
            return false
        }
        let digest = Data(SHA256.hash(data: data))
        return digest == UserDefaults.standard.data(forKey: "\(serverHost)|\(courseId)")
    }
}
