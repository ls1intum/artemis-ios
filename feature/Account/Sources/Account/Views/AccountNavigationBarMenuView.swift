//
//  SwiftUIView.swift
//
//
//  Created by Sven Andabaka on 10.02.23.
//

import SwiftUI
import DesignLibrary
import Common

struct AccountNavigationBarMenuView: View {
    @StateObject private var viewModel = AccountNavigationBarMenuViewModel()

    @Binding var error: UserFacingError?

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
        .loadingIndicator(isLoading: $viewModel.isLoading)
        .onChange(of: viewModel.error) { error in
            self.error = error
        }
    }
}

struct AccountMenu: ViewModifier {

    @Binding var error: UserFacingError?

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    AccountNavigationBarMenuView(error: $error)
                }
            }
    }
}

public extension View {
    func accountMenu(error: Binding<UserFacingError?>) -> some View {
        modifier(AccountMenu(error: error))
    }
}
