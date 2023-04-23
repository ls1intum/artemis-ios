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

struct CreateChannelView: View {

    @Environment(\.dismiss) var dismiss

    @StateObject private var viewModel = CreateChannelViewModel()

    @State private var name = ""
    @State private var description = ""

    @State private var isPrivate = false
    @State private var isAnnouncement = false

    let courseId: Int

    var body: some View {
        NavigationView {
            VStack(alignment: .leading, spacing: .l) {
                Text("Name")
                    .font(.headline)
                HStack {
                    Text("#")
                    TextField("Name", text: $name)
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

                Text("Description (Optional)")
                    .font(.headline)
                TextField("Description", text: $description)
                    .textFieldStyle(ArtemisTextField())

                Divider()
                Group {
                    VStack(alignment: .leading) {
                        Toggle("Private Channel?", isOn: $isPrivate)
                            .tint(.Artemis.toggleColor)
                        Text("Every user except instructors will need an invitation to join a private channel. Everybody can join a public channel.")
                            .font(.caption2)
                            .foregroundColor(.Artemis.secondaryLabel)
                    }

                    VStack(alignment: .leading) {
                        Toggle("Announcement Channel?", isOn: $isAnnouncement)
                            .tint(.Artemis.toggleColor)
                        Text("Only instructors and channel moderators can create new messages in an announcement channel. Students can only read the messages and answer to them.")
                            .font(.caption2)
                            .foregroundColor(.Artemis.secondaryLabel)
                    }
                }

                Button("Create Channel") {
                    Task(priority: .userInitiated) {
                        let success = await viewModel.createChannel(for: courseId,
                                                                    name: name,
                                                                    description: description.isEmpty ? nil : description,
                                                                    isPrivate: isPrivate,
                                                                    isAnnouncement: isAnnouncement)

                        if success {
                            dismiss()
                        }
                    }
                }.buttonStyle(ArtemisButton())

                Spacer()
            }
                .padding(.horizontal, .l)
                .navigationTitle("Create Channel")
                .toolbar {
                    ToolbarItem(placement: .navigationBarLeading) {
                        Button("Cancel") {
                            dismiss()
                        }
                    }
                }
        }
    }
}
