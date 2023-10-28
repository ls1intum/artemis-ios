//
//  CodeOfConductStorageService.swift
//
//
//  Created by Nityananda Zbil on 24.10.23.
//

import Common

protocol CodeOfConductStorageService {

    /**
     * Accept the code of conduct's contents locally.
     */
    func acceptCodeOfConduct(for courseId: Int, codeOfConduct: String)

    /**
     * Get the agreement for the code of conduct's contents locally.
     */
    func getAgreement(for courseId: Int, codeOfConduct: String) -> Bool
}

enum CodeOfConductStorageServiceFactory {
    static let shared: CodeOfConductStorageService = CodeOfConductStorageServiceImpl()
}
