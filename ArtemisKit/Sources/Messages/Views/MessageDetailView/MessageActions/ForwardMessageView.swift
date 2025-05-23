//
//  ForwardMessageView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 23.05.25.
//

import SharedModels
import SwiftUI

struct ForwardMessageView: View {
    let viewModel: MessageActionsViewModel

    @State private var sendViewModel: SendMessageViewModel

    init(viewModel: MessageActionsViewModel) {
        self.viewModel = viewModel

        let course = viewModel.conversationViewModel.course
        let conversation = viewModel.conversationViewModel.conversation
        let delegate = SendMessageViewModelDelegate(presentError: viewModel.conversationViewModel.presentError,
                                                    sendMessage: viewModel.forwardMessage)

        _sendViewModel = State(initialValue: SendMessageViewModel(course: course,
                                                                  conversation: conversation,
                                                                  configuration: .message,
                                                                  delegate: delegate))
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                Text("Conversation")

                Section {
                    SendMessageView(viewModel: sendViewModel)
                }
            }
            .navigationTitle("Forward message")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(R.string.localizable.cancel()) {
                        viewModel.showForwardSheet = false
                    }
                }
            }
        }
        .fontWeight(.regular)
        .presentationDetents([.medium, .large])
    }
}
