//
//  CodeOfConductStorageService.swift
//
//
//  Created by Nityananda Zbil on 24.10.23.
//

import Common

protocol CodeOfConductStorageService {

    /**
     * Accept the content of the code of conduct locally.
     */
    func acceptCodeOfConduct(for courseId: Int, codeOfConduct: String) async -> NetworkResponse

    /**
     * Get the agreement for the content of the code of conduct locally.
     */
    func getAgreement(for courseId: Int, codeOfConduct: String) async -> DataState<Bool>
}

enum CodeOfConductStorageServiceFactory {
    static let shared: CodeOfConductStorageService = CodeOfConductStorageServiceImpl()
}
