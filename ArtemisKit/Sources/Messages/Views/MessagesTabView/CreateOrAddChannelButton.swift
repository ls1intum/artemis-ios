//
//  CreateOrAddChannelButton.swift
//
//
//  Created by Anian Schleyer on 20.08.24.
//

import SwiftUI

struct CreateOrAddChannelButton: View {
    @ObservedObject var viewModel: MessagesAvailableViewModel

    @State private var isCreateNewConversationPresented = false
    @State private var isNewConversationDialogPresented = false
    @State private var isBrowseChannelsPresented = false
    @State private var isCreateChannelPresented = false

    var body: some View {
        Group {
            if viewModel.course.courseInformationSharingConfiguration == .communicationOnly && !viewModel.course.isAtLeastTutorInCourse {
                // If DMs are disabled and we are no instructor, we can only browse channels
                Button {
                    isBrowseChannelsPresented = true
                } label: {
                    menuIcon
                }
            } else {
                Menu {
                    menuContent
                } label: {
                    menuIcon
                }
            }
        }
        .sheet(isPresented: $isCreateNewConversationPresented) {
            CreateOrAddToChatView(courseId: viewModel.courseId, configuration: .createChat)
        }
        .sheet(isPresented: $isCreateChannelPresented) {
            Task {
                await viewModel.loadConversations()
            }
        } content: {
            CreateChannelView(courseId: viewModel.courseId)
        }
        .sheet(isPresented: $isBrowseChannelsPresented) {
            Task {
                await viewModel.loadConversations()
            }
        } content: {
            BrowseChannelsView(courseId: viewModel.courseId)
        }
    }

    @ViewBuilder private var menuContent: some View {
        if viewModel.course.isAtLeastTutorInCourse {
            Button(R.string.localizable.createChannel(), systemImage: "plus.bubble.fill") {
                isCreateChannelPresented = true
            }
        }
        Button(R.string.localizable.browseChannels(), systemImage: "number") {
            isBrowseChannelsPresented = true
        }
        if viewModel.course.courseInformationSharingConfiguration == .communicationAndMessaging {
            Button(R.string.localizable.createChat(), systemImage: "bubble.left.fill") {
                isCreateNewConversationPresented = true
            }
        }
    }

    private var menuIcon: some View {
        Image(systemName: "plus.bubble")
            .foregroundStyle(.white)
            .font(.title2)
            .padding()
            .background(Color.Artemis.artemisBlue, in: .circle)
            .shadow(color: Color.gray.opacity(0.2), radius: .m)
    }
}
