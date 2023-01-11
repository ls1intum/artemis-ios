//
//  File.swift
//  
//
//  Created by Sven Andabaka on 09.01.23.
//

import Foundation

public protocol LoginService {

    /**
     * Perform a login request to the server.
     */
    func login(username: String, password: String, rememberMe: Bool) async -> Bool
}

public struct LoginResponse: Decodable {
    public let idToken: String

    enum CodingKeys: String, CodingKey {
        case idToken = "id_token"
    }
}

enum LoginServiceFactory {
    
    static let shared: LoginService = LoginServiceImpl()
    
}
