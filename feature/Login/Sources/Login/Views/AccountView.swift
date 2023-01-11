import Foundation
import SwiftUI

public extension View {
    func accountDestination(onLoggedIn: @escaping () -> Void) -> some View {
        navigationDestination(for: AccountDest.self) { _ in
            AccountView(onLoggedIn: onLoggedIn)
        }
    }
}

public extension NavigationPath {
    mutating func appendAccountView() {
        append(AccountDest())
    }
}

struct AccountView: View {

    let onLoggedIn: () -> Void

    var body: some View {
        LoginView(onLoggedIn: onLoggedIn)
                .navigationBarBackButtonHidden()
    }
}

struct AccountDest: Hashable {
}