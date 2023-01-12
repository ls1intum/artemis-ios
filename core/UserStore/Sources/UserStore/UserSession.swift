//
//  File.swift
//
//
//  Created by Sven Andabaka on 09.01.23.
//

import Foundation

public class UserSession: ObservableObject {
    
    @Published public private(set) var bearerToken: String? = nil
    
    public static let shared = UserSession()
    
    private init() {
        guard let data = KeychainHelper.shared.read(service: "bearerToken", account: "Artemis") else { return }
        bearerToken = String(data: data, encoding: .utf8)
    }
    
    public func saveBearerToken(token: String?) {
        guard let token = token else {
            bearerToken = nil
            KeychainHelper.shared.delete(service: "bearerToken", account: "Artemis")
            return
        }
        
        bearerToken = token
        let data = Data(token.utf8)
        KeychainHelper.shared.save(data, service: "bearerToken", account: "Artemis")
    }
}
