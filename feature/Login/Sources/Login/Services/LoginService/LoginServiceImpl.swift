//
//  File.swift
//  
//
//  Created by Sven Andabaka on 09.01.23.
//

import Foundation
import APIClient
import UserStore

class LoginServiceImpl: LoginService {
    
    private let client = APIClient()

    struct LoginUser: APIRequest {
        typealias Response = LoginResponse
        
        var username: String
        var password: String
        var rememberMe: Bool
        
        var method: HTTPMethod {
            return .post
        }
        
        var resourceName: String {
            return "api/authenticate"
        }
    }
    
    func login(username: String, password: String, rememberMe: Bool) async -> Bool {
        let result = await client.send(LoginUser(username: username, password: password, rememberMe: rememberMe))
        
        switch result {
        case .success((let response, _)):
            UserSession.shared.saveBearerToken(token: response.idToken)
            return true
        case .failure:
            return false
        }
    }
}
