//
//  CodeOfConductStorageService.swift
//
//
//  Created by Nityananda Zbil on 24.10.23.
//

import Common
import SharedModels

protocol CodeOfConductStorageService {
    func getCodeOfConductAgreement(for course: Course) async -> DataState<Bool>
    func acceptCodeOfConduct(for course: Course) async -> NetworkResponse
}

enum CodeOfConductStorageServiceFactory {
    static let shared: CodeOfConductStorageService = CodeOfConductStorageServiceImpl()
}
