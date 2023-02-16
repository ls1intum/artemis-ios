//
//  File.swift
//
//
//  Created by Sven Andabaka on 09.01.23.
//

import Foundation
import Common

public protocol LoginService {
    /**
     * Perform a login request to the server.
     */
    func login(username: String, password: String, rememberMe: Bool) async -> NetworkResponse
}

enum LoginServiceFactory {
    static let shared: LoginService = LoginServiceImpl()
}
