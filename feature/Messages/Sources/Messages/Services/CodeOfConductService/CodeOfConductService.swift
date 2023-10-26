//
//  CodeOfConductService.swift
//
//
//  Created by Nityananda Zbil on 26.10.23.
//

import Common

protocol CodeOfConductService {
    /**
     * Perform a get request for the code of conduct template.
     */
    func getCodeOfConductTemplate() async -> DataState<String>

    /**
     * Perform a get request to check if the code of conduct is accepted.
     */
    func getCodeOfConductAgreement(for courseId: Int) async -> DataState<Bool>

    /**
     * Perform a path request to accept the code of conduct.
     */
    func acceptCodeOfConduct(for courseId: Int) async -> NetworkResponse

    /**
     * Perform a get request for the responsible users.
     */
    func getCodeOfConductResponsibleUsers(for courseId: Int) async -> DataState<[ResponsibleUserDTO]>
}

enum CodeOfConductServiceFactory {
    static let shared: CodeOfConductService = CodeOfConductServiceImpl()
}
