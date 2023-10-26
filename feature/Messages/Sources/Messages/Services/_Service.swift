//
//  _Service.swift
//
//
//  Created by Nityananda Zbil on 24.10.23.
//

import APIClient
import Common
import Foundation
import SharedModels
import UserStore

// swiftlint:disable:next type_name
protocol _Service {
    func getCodeOfConductAgreement(for course: Course) async -> DataState<Bool>
    func acceptCodeOfConduct(for course: Course) async -> NetworkResponse
}

// swiftlint:disable:next type_name
enum _ServiceFactory {
    static let shared: _Service = _ServiceImpl()
}

// swiftlint:disable:next type_name
struct _ServiceImpl: _Service {
    func getCodeOfConductAgreement(for course: Course) async -> DataState<Bool> {
        guard let serverHost = UserSession.shared.institution?.baseURL?.absoluteString else {
            return .failure(error: .init(title: "No base URL"))
        }
        let hashValue = course.courseInformationSharingMessagingCodeOfConduct?.hashValue
        let expected = UserDefaults.standard.integer(forKey: "\(serverHost)|\(course.id)")
        return .done(response: hashValue == expected)
    }

    func acceptCodeOfConduct(for course: Course) async -> NetworkResponse {
        guard let serverHost = UserSession.shared.institution?.baseURL?.absoluteString else {
            return .init(error: .invalidURL)
        }
        let hashValue = course.courseInformationSharingMessagingCodeOfConduct?.hashValue
        UserDefaults.standard.set(hashValue, forKey: "\(serverHost)|\(course.id)")
        return .success
    }
}
