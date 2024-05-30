//
//  SendMessageMentionContentView.swift
//
//
//  Created by Nityananda Zbil on 30.05.24.
//

import SwiftUI

struct SendMessageMentionContentView: View {

    @Bindable var viewModel: SendMessageViewModel

    var body: some View {
        NavigationStack {
            List {
                Button {
                    viewModel.didTapAtButton()
                    viewModel.modalPresentation.toggle()
                } label: {
                    Label("Members", systemImage: "at")
                }
                Button {
                    viewModel.didTapNumberButton()
                    viewModel.modalPresentation.toggle()
                } label: {
                    Label("Channels", systemImage: "number")
                }

                let delegate = SendMessagePickerDelegate { mention in
                    viewModel.text.append(mention)
                    viewModel.modalPresentation.toggle()
                }
                NavigationLink {
                    SendMessageExercisePicker(delegate: delegate, course: viewModel.course)
                } label: {
                    Label("Exercises", systemImage: "list.bullet.clipboard")
                }
                NavigationLink {
                    SendMessageLecturePicker(course: viewModel.course, delegate: delegate)
                } label: {
                    Label("Lectures", systemImage: "character.book.closed")
                }
            }
            .listStyle(.plain)
            .navigationTitle("Mention")
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
