import Foundation
import SwiftUI

struct AccountView: View {

    let onLoggedIn: () -> Void

    var body: some View {
        LoginView(onLoggedIn: onLoggedIn)
                .navigationBarBackButtonHidden()
    }
}