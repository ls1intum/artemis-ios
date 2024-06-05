//
//  CodeOfConductService.swift
//
//
//  Created by Nityananda Zbil on 26.10.23.
//

import Common

protocol CodeOfConductService {

    /**
     * Perform a patch request to accept the code of conduct.
     */
    func acceptCodeOfConduct(for courseId: Int) async -> NetworkResponse

    /**
     * Perform a get request to check if the code of conduct is accepted.
     */
    func getAgreement(for courseId: Int) async -> DataState<Bool>

    /**
     * Perform a get request for the responsible users.
     */
    func getResponsibleUsers(for courseId: Int) async -> DataState<[ResponsibleUserDTO]>

    /**
     * Perform a get request for the code of conduct template.
     */
    func getTemplate() async -> DataState<String>
}

enum CodeOfConductServiceFactory {
    @StubOrImpl(stub: CodeOfConductServiceStub(), impl: CodeOfConductServiceImpl())
    static var shared: CodeOfConductService
}
