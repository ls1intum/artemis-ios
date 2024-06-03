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
                    viewModel.isMentionContentViewPresented.toggle()
                } label: {
                    Label(R.string.localizable.members(), systemImage: "at")
                }
                Button {
                    viewModel.didTapNumberButton()
                    viewModel.isMentionContentViewPresented.toggle()
                } label: {
                    Label(R.string.localizable.channels(), systemImage: "number")
                }

                let delegate = SendMessageMentionContentDelegate { [weak viewModel] mention in
                    viewModel?.text.append(mention)
                    viewModel?.isMentionContentViewPresented.toggle()
                }
                NavigationLink {
                    SendMessageExercisePicker(delegate: delegate, course: viewModel.course)
                } label: {
                    Label(R.string.localizable.exercises(), systemImage: "list.bullet.clipboard")
                }
                NavigationLink {
                    SendMessageLecturePicker(course: viewModel.course, delegate: delegate)
                } label: {
                    Label(R.string.localizable.lectures(), systemImage: "character.book.closed")
                }
            }
            .listStyle(.plain)
            .navigationTitle(R.string.localizable.mention())
            .navigationBarTitleDisplayMode(.inline)
        }
    }
}
