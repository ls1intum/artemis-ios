//
//  File.swift
//  
//
//  Created by Sven Andabaka on 12.01.23.
//

import Foundation
import Model
import Data
import APIClient


protocol AccountService {
    
    /**
     Get the details about the account of the logged in user from the server.
     Automatically retries on failure.
     */
    func getAccountData() async -> DataState<Account>
}

enum AccountServiceFactory {
    
    static let shared: AccountService = AccountServiceImpl()
    
}
