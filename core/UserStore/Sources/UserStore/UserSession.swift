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
        guard let rememberData = KeychainHelper.shared.read(service: "shouldRemember", account: "Artemis"),
              String(data: rememberData, encoding: .utf8) == "true",
              let tokenData = KeychainHelper.shared.read(service: "bearerToken", account: "Artemis") else { return }
        bearerToken = String(data: tokenData, encoding: .utf8)
    }
    
    public func saveBearerToken(token: String?, shouldRemember: Bool) {
        guard let token = token else {
            bearerToken = nil
            KeychainHelper.shared.delete(service: "bearerToken", account: "Artemis")
            KeychainHelper.shared.delete(service: "shouldRemember", account: "Artemis")
            return
        }
        
        bearerToken = token
        let tokenData = Data(token.utf8)
        let rememberData = Data(shouldRemember.description.utf8)
        KeychainHelper.shared.save(tokenData, service: "bearerToken", account: "Artemis")
        KeychainHelper.shared.save(rememberData, service: "shouldRemember", account: "Artemis")
    }
}
