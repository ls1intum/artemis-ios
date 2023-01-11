import Foundation
import SwiftUI

struct LoginView: View {

    let onLoggedIn: () -> Void

    @StateObject private var viewModel = LoginViewModel()

    @State private var username: String = ""
    @State private var password: String = ""
    @State private var rememberMe: Bool = false

    @State private var displayLoginFailureDialog = false

    var body: some View {
        VStack {
            Spacer()

            Text("Welcome to Artemis!")
                    .font(.system(size: 35, weight: .bold))
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

            Text("Please login with your TUM login credentials.")
                    .font(.system(size: 25))
                    .padding(.horizontal, 10)
                    .frame(maxWidth: .infinity)
                    .multilineTextAlignment(.center)

            VStack(spacing: 10) {
                TextField("Username", text: $username)
                        .textFieldStyle(.roundedBorder)
                SecureField("Password", text: $password)
                        .textFieldStyle(.roundedBorder)

                Toggle("Automatic login", isOn: $rememberMe)
                        .toggleStyle(.switch)
            }
                    .frame(maxWidth: .infinity)
                    .padding(.horizontal, 40)

            Button("Login", action: {
                Task {
                    let response = await viewModel.login(username: username, password: password, rememberMe: rememberMe)

                    if !response {
                        displayLoginFailureDialog = true
                    }
                }
            })
                    .frame(maxWidth: .infinity)
                    .disabled(username.isEmpty || password.isEmpty)
                    .buttonStyle(.borderedProminent)

            Spacer()
        }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .alert("Login failed", isPresented: $displayLoginFailureDialog) {
                    Button("OK", role: .cancel) {}
                }
    }
}
