//
//  SwiftUIView.swift
//
//
//  Created by Sven Andabaka on 10.02.23.
//

import SwiftUI
import DesignLibrary
import Common
import PushNotifications

struct AccountNavigationBarMenuView: View {
    @StateObject private var viewModel = AccountNavigationBarMenuViewModel()

    @Binding var error: UserFacingError?

    @State private var showNotificationSettings = false

    var body: some View {
        Menu(content: {
            DataStateView(data: $viewModel.account, retryHandler: viewModel.getAccount) { account in
                Text(account.login)
            }
            Button(action: {
                showNotificationSettings = true
            }, label: {
                HStack {
                    Image(systemName: "gearshape.fill")
                    Text("Notification Settings")
                    Spacer()
                }
            })
            Button("Logout") {
                viewModel.logout()
            }
        }, label: {
            HStack(alignment: .center, spacing: .s) {
                Spacer()
                Image(systemName: "person.fill")
                Text(viewModel.account.value?.login ?? "xx12xxx")
                    .redacted(reason: viewModel.account.value == nil ? .placeholder : [])
                Image(systemName: "arrowtriangle.down.fill")
                    .scaleEffect(0.5)
            }.frame(width: 150)
        })
        .onChange(of: viewModel.error) { error in
            self.error = error
        }
        .sheet(isPresented: $showNotificationSettings) {
            PushNotificationSettingsView()
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
