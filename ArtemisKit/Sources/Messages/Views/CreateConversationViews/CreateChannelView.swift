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

    @State private var viewModel = CreateChannelViewModel()

    let courseId: Int

    var body: some View {
        NavigationStack {
            Form {
                Section(R.string.localizable.channelNameLabel()) {
                    VStack {
                        HStack {
                            Text("#")
                            TextField(R.string.localizable.channelNameLabel(), text: $viewModel.name)
                                .textInputAutocapitalization(.never)
                                .autocorrectionDisabled(true)
                        }

                        if let warningText = viewModel.nameFormatText {
                            Text(warningText)
                                .foregroundColor(.Artemis.badgeDangerColor)
                                .font(.caption)
                        }
                    }
                }

                Section(R.string.localizable.descriptionOptional()) {
                    TextField(R.string.localizable.description(), text: $viewModel.description)
                }

                Section {
                    VStack(alignment: .leading) {
                        Picker(R.string.localizable.channelType(), selection: $viewModel.channelType) {
                            ForEach(ChannelType.allCases, id: \.self) { type in
                                Text(type.title)
                            }
                        }
                        Text(viewModel.channelType.description)
                            .font(.caption2)
                            .foregroundColor(.Artemis.secondaryLabel)
                    }

                    VStack(alignment: .leading) {
                        Toggle(R.string.localizable.announcementChannelLabel(), isOn: $viewModel.isAnnouncement)
                            .tint(.Artemis.toggleColor)
                        Text(R.string.localizable.announcementChannelDescription())
                            .font(.caption2)
                            .foregroundColor(.Artemis.secondaryLabel)
                    }
                }

                Button(R.string.localizable.createChannelButtonLabel()) {
                    Task(priority: .userInitiated) {
                        let newChannelId = await viewModel.createChannel(for: courseId)

                        if let newChannelId {
                            dismiss()
                            navigationController.goToCourseConversation(courseId: courseId, conversationId: newChannelId)
                        }
                    }
                }
                .buttonStyle(ArtemisButton())
                .frame(maxWidth: .infinity, alignment: .trailing)
                .listRowBackground(Color.clear)
            }
            .listRowSpacing(0)
            .navigationTitle(R.string.localizable.createChannelNavTitel())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(R.string.localizable.cancel()) {
                        dismiss()
                    }
                }
            }
            .alert(isPresented: viewModel.showError, error: viewModel.error, actions: {})
        }
    }
}
