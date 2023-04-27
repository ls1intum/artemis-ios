//
//  CreateChannelView.swift
//  
//
//  Created by Sven Andabaka on 23.04.23.
//

import SwiftUI
import DesignLibrary
import SharedModels
import Common
import Navigation

struct CreateChannelView: View {

    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var navigationController: NavigationController

    @StateObject private var viewModel = CreateChannelViewModel()

    @State private var name = ""
    @State private var description = ""

    @State private var isPrivate = false
    @State private var isAnnouncement = false

    let courseId: Int

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: .l) {
                Text(R.string.localizable.channelNameLabel())
                    .font(.headline)
                HStack {
                    Text("#")
                    TextField(R.string.localizable.channelNameLabel(), text: $name)
                        .textFieldStyle(ArtemisTextField())
                        .textInputAutocapitalization(.never)
                        .autocorrectionDisabled(true)
                }

                if let warningText = viewModel.nameFormatText {
                    Text(warningText)
                        .foregroundColor(.Artemis.badgeDangerColor)
                        .font(.caption)
                }

                Divider()

                Text(R.string.localizable.descriptionOptional())
                    .font(.headline)
                TextField(R.string.localizable.description(), text: $description)
                    .textFieldStyle(ArtemisTextField())

                Divider()
                Group {
                    VStack(alignment: .leading) {
                        Toggle(R.string.localizable.privateChannelLabel(), isOn: $isPrivate)
                            .tint(.Artemis.toggleColor)
                        Text(R.string.localizable.privateChannelDescription())
                            .font(.caption2)
                            .foregroundColor(.Artemis.secondaryLabel)
                    }

                    VStack(alignment: .leading) {
                        Toggle(R.string.localizable.announcementChannelLabel(), isOn: $isAnnouncement)
                            .tint(.Artemis.toggleColor)
                        Text(R.string.localizable.announcementChannelDescription())
                            .font(.caption2)
                            .foregroundColor(.Artemis.secondaryLabel)
                    }
                }

                Button(R.string.localizable.createChannelButtonLabel()) {
                    Task(priority: .userInitiated) {
                        let newChannelId = await viewModel.createChannel(for: courseId,
                                                                         name: name,
                                                                         description: description.isEmpty ? nil : description,
                                                                         isPrivate: isPrivate,
                                                                         isAnnouncement: isAnnouncement)

                        if let newChannelId {
                            dismiss()
                            navigationController.goToCourseConversation(courseId: courseId, conversationId: newChannelId)
                        }
                    }
                }.buttonStyle(ArtemisButton())

                Spacer()
            }
                .padding(.horizontal, .l)
                .navigationTitle(R.string.localizable.createChannelNavTitel())
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button(R.string.localizable.cancel()) {
                            dismiss()
                        }
                    }
                }
                .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
        }
    }
}
