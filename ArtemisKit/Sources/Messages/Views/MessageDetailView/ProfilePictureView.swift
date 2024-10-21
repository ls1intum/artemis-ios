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
    let size: CGFloat

    init(user: ConversationUser, role: UserRole?, course: Course, size: CGFloat = 44) {
        self._viewModel = State(initialValue: ProfileViewModel(course: course, user: user, role: role))
        self.size = size
    }

    var body: some View {
        Button {
            viewModel.showProfileSheet = true
        } label: {
            if let url = viewModel.user.imagePath {
                ArtemisAsyncImage(imageURL: url) {
                    DefaultProfilePictureView(viewModel: viewModel)
                }
            } else {
                DefaultProfilePictureView(viewModel: viewModel, font: size < 35 ? .caption.bold() : .headline.bold())
            }
        }
        .frame(width: size, height: size)
        .clipShape(.rect(cornerRadius: .m))
        .sheet(isPresented: $viewModel.showProfileSheet) {
            ProfileInfoSheet(viewModel: viewModel)
        }
    }
}

private struct DefaultProfilePictureView: View {
    let viewModel: ProfileViewModel
    var font: Font = .headline.bold()

    var body: some View {
        ZStack {
            Rectangle()
                .fill(backgroundColor)
            Text(initials)
                .font(font)
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
                    if let name = viewModel.user.name {
                        HStack(alignment: .center, spacing: .l) {
                            Group {
                                if let profileUrl = viewModel.user.imagePath {
                                    ArtemisAsyncImage(imageURL: profileUrl) {}
                                } else {
                                    DefaultProfilePictureView(viewModel: viewModel, font: .largeTitle)
                                }
                            }
                            .frame(width: 100, height: 100)
                            .clipShape(.rect(cornerRadius: 8))

                            VStack(alignment: .leading, spacing: .m) {
                                if let role = viewModel.role {
                                    Chip(text: role.displayName,
                                         backgroundColor: role.badgeColor,
                                         horizontalPadding: .m,
                                         verticalPadding: .s)
                                    .font(.body)
                                    // For visual alignment
                                    .padding(.top, .m)
                                }

                                Text(name)
                                    .font(.title)
                                    .multilineTextAlignment(.leading)
                            }
                        }
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .listRowInsets(EdgeInsets())
                        .listRowBackground(Color.clear)
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
            .navigationTitle(R.string.localizable.profile())
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
