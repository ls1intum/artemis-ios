//
//  File.swift
//  
//
//  Created by Sven Andabaka on 10.02.23.
//

import Foundation
import Common
import APIClient

@MainActor
class AccountNavigationBarMenuViewModel: ObservableObject {
    @Published var account: DataState<Account> = .loading

    init() {
        Task {
            await getAccount()
        }
    }

    func getAccount() async {
        account = await AccountServiceFactory.shared.getAccount()
    }

    func logout() {
        APIClient().perfomLogout()
    }
}
