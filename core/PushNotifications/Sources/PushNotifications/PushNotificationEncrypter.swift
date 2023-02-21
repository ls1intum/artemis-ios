//
//  File.swift
//  
//
//  Created by Sven Andabaka on 19.02.23.
//

import Foundation
import CryptoSwift
import UserStore

class PushNotificationEncrypter {

    // TODO: decrypt does not work: invalidKeySize with .utf8 dataPaddingRequired with base64 ... try ...
    static func decrypt(payload: String, iv: String) -> PushNotification? {
        guard let privateKey = UserSession.shared.notificationsEncryptionKey else { return nil }
        print("Private Key: " + privateKey)
        let key = Array(privateKey.utf8)
        let iv = Array(iv.utf8)

        do {
            let decrypted = try AES(key: key, blockMode: CBC(iv: iv), padding: .pkcs7).decrypt(Array(payload.utf8))
            let decoder = JSONDecoder()
            return try decoder.decode(PushNotification.self, from: Data(decrypted))
        } catch {
            print("error encrypting: \(error)")
            return nil
        }
    }
}
