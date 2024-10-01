//
//  ProfilePictureView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 11.09.24.
//

import DesignLibrary
import Navigation
import SharedModels
import SwiftUI

struct ProfilePictureView: View {
    @State private var viewModel: ProfileViewModel

    init(user: ConversationUser, course: Course) {
        self._viewModel = State(initialValue: ProfileViewModel(course: course, user: user))
    }

    var body: some View {
        Button {
            viewModel.showProfileSheet = true
        } label: {
            if let url = viewModel.user.imagePath {
                ArtemisAsyncImage(imageURL: url) {
                    defaultProfilePicture
                }
            } else {
                defaultProfilePicture
            }
        }
        .frame(width: 44, height: 44)
        .clipShape(.rect(cornerRadius: .m))
        .sheet(isPresented: $viewModel.showProfileSheet) {
            ProfileInfoSheet(viewModel: viewModel)
        }
    }

    @ViewBuilder var defaultProfilePicture: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)
            Text(initials)
                .font(.headline.bold())
                .fontDesign(.rounded)
                .foregroundStyle(.white)
        }
        .accessibilityHidden(true)
    }

    private var initials: String {
        let nameComponents = viewModel.user.name?.split(separator: " ")
        let initialFirstName = nameComponents?.first?.prefix(1) ?? ""
        let initialLastName = nameComponents?.last?.prefix(1) ?? ""
        let initials = initialFirstName + initialLastName
        if initials.isEmpty {
            return "NA"
        } else {
            return String(initials)
        }
    }

    private var backgroundColor: Color {
        let hash = abs(String(viewModel.user.id).hashValue) % 255
        return Color(hue: Double(hash) / 255, saturation: 0.5, brightness: 0.5)
    }
}

struct ProfileInfoSheet: View {
    @EnvironmentObject var navController: NavigationController
    @Environment(\.dismiss) var dismiss
    let viewModel: ProfileViewModel

    var body: some View {
        @Bindable var viewModel = viewModel
        NavigationStack {
            List {
                Group {
                    if let profileUrl = viewModel.user.imagePath {
                        VStack(alignment: .leading) {
                            ArtemisAsyncImage(imageURL: profileUrl) {}
                                .frame(width: 100, height: 100)
                                .clipShape(.rect(cornerRadius: .m))
                            if let name = viewModel.user.name {
                                Text(name)
                                    .font(.title)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
                    } else if let name = viewModel.user.name {
                        Section(R.string.localizable.name()) {
                            Text(name)
                        }
                    }
                    
                    if viewModel.canSendMessage {
                        Section(R.string.localizable.actions()) {
                            Button(R.string.localizable.sendMessage(), systemImage: "bubble.fill") {
                                viewModel.openConversation(navigationController: navController) {
                                    dismiss()
                                }
                            }
                        }
                    }
                }
                .listRowBackground(
                    Spacer()
                        .background(.primary.opacity(0.15))
                        .background(.thinMaterial)
                )
            }
            .navigationTitle(viewModel.user.name ?? R.string.localizable.profile())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .confirmationAction) {
                    Button(R.string.localizable.done()) {
                        dismiss()
                    }
                }
            }
            .scrollContentBackground(.hidden)
            .background(backgroundImage)
        }
        .task {
            await viewModel.loadUserLogin()
        }
        .loadingIndicator(isLoading: $viewModel.isLoading)
        .alert(isPresented: Binding(get: {
            viewModel.error != nil
        }, set: { newValue in
            if !newValue {
                viewModel.error = nil
            }
        }), error: viewModel.error, actions: {})
    }

    @ViewBuilder private var backgroundImage: some View {
        if let profileUrl = viewModel.user.imagePath {
            ArtemisAsyncImage(imageURL: profileUrl) {}
                .scaledToFill()
                .ignoresSafeArea()
                .blur(radius: .l, opaque: true)
                .opacity(0.15)
        }
    }
}
