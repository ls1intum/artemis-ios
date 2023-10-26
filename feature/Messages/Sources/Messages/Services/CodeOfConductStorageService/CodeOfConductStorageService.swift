//
//  CodeOfConductStorageService.swift
//
//
//  Created by Nityananda Zbil on 24.10.23.
//

import Common

protocol CodeOfConductStorageService {
    func getAgreement(for courseId: Int, codeOfConduct: String) async -> DataState<Bool>
    func accept(for courseId: Int, codeOfConduct: String) async -> NetworkResponse
}

enum CodeOfConductStorageServiceFactory {
    static let shared: CodeOfConductStorageService = CodeOfConductStorageServiceImpl()
}
