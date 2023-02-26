//
//  SwiftUIView.swift
//  
//
//  Created by Sven Andabaka on 10.02.23.
//

import SwiftUI
import Common

struct AccountNavigationBarMenuView: View {
    @StateObject private var viewModel = AccountNavigationBarMenuViewModel()

    var body: some View {
        Menu(content: {
            DataStateView(data: $viewModel.account, retryHandler: viewModel.getAccount) { account in
                Text(account.login)
            }
            Button("Logout") {
                viewModel.logout()
            }
        }, label: {
            HStack(spacing: 4) {
                Image(systemName: "person.fill")
                DataStateView(data: $viewModel.account, retryHandler: viewModel.getAccount) { account in
                    Text(account.login)
                }
                Image(systemName: "arrowtriangle.down.fill")
                    .scaleEffect(0.3)
            }
        })
        .padding(.horizontal, 16)
    }
}

struct AccountMenu: ViewModifier {
    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    AccountNavigationBarMenuView()
                }
            }
    }
}

public extension View {
    func accountMenu() -> some View {
        modifier(AccountMenu())
    }
}
