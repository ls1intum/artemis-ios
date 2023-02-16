//
//  File.swift
//
//
//  Created by Sven Andabaka on 12.01.23.
//

import Foundation
import Model
import APIClient

class AccountServiceImpl: AccountService {

    let client = APIClient()

    struct AccountRequest: APIRequest {
        typealias Response = Account

        var method: HTTPMethod {
            return .get
        }

        var resourceName: String {
            return "api/account"
        }
    }

    func getAccountData() async -> DataState<Account> {
        let result = await client.send(AccountRequest())

        switch result {
        case .success((let response, _)):
            return .done(response: response)
        case .failure(let error):
            return .failure(error: error)
        }
    }

}
