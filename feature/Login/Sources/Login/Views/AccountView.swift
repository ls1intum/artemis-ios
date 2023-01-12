import Foundation
import SwiftUI

public extension View {
    func accountDestination() -> some View {
        navigationDestination(for: AccountDest.self) { _ in
            AccountView()
        }
    }
}

public extension NavigationPath {
    mutating func appendAccountView() {
        append(AccountDest())
    }
}

struct AccountView: View {

    var body: some View {
        LoginView()
                .navigationBarBackButtonHidden()
    }
}

struct AccountDest: Hashable {
}
