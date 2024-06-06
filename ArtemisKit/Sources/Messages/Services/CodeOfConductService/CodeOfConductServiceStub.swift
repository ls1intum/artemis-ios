//
//  CodeOfConductServiceStub.swift
//
//
//  Created by Anian Schleyer on 03.06.24.
//

import Foundation
import Common

struct CodeOfConductServiceStub: CodeOfConductService {
    func acceptCodeOfConduct(for courseId: Int) async -> NetworkResponse {
        return .success
    }

    func getAgreement(for courseId: Int) async -> DataState<Bool> {
        return .done(response: true)
    }

    func getResponsibleUsers(for courseId: Int) async -> DataState<[ResponsibleUserDTO]> {
        return .done(response: [])
    }

    func getTemplate() async -> DataState<String> {
        return .done(response: "")
    }
}
