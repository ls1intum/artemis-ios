//
//  SendMessageView.swift
//
//
//  Created by Sven Andabaka on 08.04.23.
//

import Common
import DesignLibrary
import SharedModels
import SwiftUI

struct SendMessageView: View {

    @State var viewModel: SendMessageViewModel

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack {
            mentions
            VStack {
                if isFocused && !viewModel.isEditing {
                    Capsule()
                        .fill(Color.secondary)
                        .frame(width: 50, height: 3)
                        .padding(.top, .m)
                }
                HStack(alignment: .bottom) {
                    textField
                        .lineLimit(10)
                        .focused($isFocused)
                        .toolbar {
                            ToolbarItem(placement: .keyboard) {
                                keyboardToolbarContent
                            }
                        }
                    if !isFocused {
                        sendButton
                    }
                }
                .padding(.horizontal, .l)
                .padding(.bottom, .l)
                .padding(.top, isFocused ? .m : .l)
            }
            .onAppear {
                viewModel.performOnAppear()
            }
            .onDisappear {
                viewModel.performOnDisappear()
            }
            .overlay {
                if viewModel.isEditing {
                    EmptyView()
                } else {
                    RoundedRectangle(cornerRadius: .m)
                        .trim(from: isFocused ? 0.52 : 0.51, to: isFocused ? 0.98 : 0.99)
                        .stroke(Color.Artemis.artemisBlue, lineWidth: 2)
                }
            }
            .gesture(
                DragGesture(minimumDistance: 30, coordinateSpace: .local)
                    .onEnded { value in
                        if value.translation.height > 0 {
                            // down
                            isFocused = false
                            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                            impactMed.impactOccurred()
                        }
                    }
            )
        }
        .sheet(item: $viewModel.modalPresentation) {
            isFocused = true
        } content: { presentation in
            switch presentation {
            case .exercisePicker:
                SendMessageExercisePicker(text: $viewModel.text, course: viewModel.course)
            case .lecturePicker:
                SendMessageLecturePicker(text: $viewModel.text, course: viewModel.course)
            }
        }
    }
}

@MainActor
private extension SendMessageView {
    @ViewBuilder var mentions: some View {
        switch viewModel.conditionalPresentation {
        case .memberPicker:
            SendMessageMentionMemberView(
                viewModel: SendMessageMentionMemberViewModel(course: viewModel.course),
                sendMessageViewModel: viewModel
            )
        case .channelPicker:
            SendMessageMentionChannelView(
                viewModel: SendMessageMentionChannelViewModel(course: viewModel.course),
                sendMessageViewModel: viewModel
            )
        case nil:
            EmptyView()
        }
    }

    @ViewBuilder var textField: some View {
        let label = R.string.localizable.messageAction(viewModel.conversation.baseConversation.conversationName)
        if viewModel.isEditing {
            TextField(label, text: $viewModel.text, axis: .vertical)
                .textFieldStyle(ArtemisTextField())
        } else {
            TextField(label, text: $viewModel.text, axis: .vertical)
        }
    }

    var keyboardToolbarContent: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Button {
                        viewModel.didTapBoldButton()
                    } label: {
                        Image(systemName: "bold")
                    }
                    Button {
                        viewModel.didTapItalicButton()
                    } label: {
                        Image(systemName: "italic")
                    }
                    Button {
                        viewModel.didTapUnderlineButton()
                    } label: {
                        Image(systemName: "underline")
                    }
                    Button {
                        viewModel.didTapBlockquoteButton()
                    } label: {
                        Image(systemName: "quote.opening")
                    }
                    Button {
                        viewModel.didTapCodeButton()
                    } label: {
                        Image(systemName: "curlybraces")
                    }
                    Button {
                        viewModel.didTapCodeBlockButton()
                    } label: {
                        Image(systemName: "curlybraces.square.fill")
                    }
                    Button {
                        viewModel.didTapLinkButton()
                    } label: {
                        Image(systemName: "link")
                    }
                    Button {
                        viewModel.didTapAtButton()
                    } label: {
                        Image(systemName: "at")
                    }
                    Button {
                        viewModel.didTapNumberButton()
                    } label: {
                        Image(systemName: "number")
                    }
                    Button {
                        isFocused = false
                        viewModel.modalPresentation = .exercisePicker
                    } label: {
                        Text(R.string.localizable.exercise())
                    }
                    Button {
                        isFocused = false
                        viewModel.modalPresentation = .lecturePicker
                    } label: {
                        Text(R.string.localizable.lecture())
                    }
                }
            }
            Spacer()
            sendButton
        }
    }

    var sendButton: some View {
        Button(action: viewModel.didTapSendButton) {
            Image(systemName: "paperplane.fill")
                .imageScale(.large)
        }
        .padding(.leading, .l)
        .disabled(viewModel.text.isEmpty)
        .loadingIndicator(isLoading: $viewModel.isLoading)
    }
}
