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

enum SendMessageType {
    case message
    case answerMessage(Message, () async -> Void)
    case editMessage(Message, () -> Void)
    case editAnswerMessage(AnswerMessage, () -> Void)
}

struct SendMessageView: View {

    @State var viewModel = SendMessageViewModel()

    @ObservedObject var conversationViewModel: ConversationViewModel

    @FocusState private var isFocused: Bool

    let sendMessageType: SendMessageType

    private var isEditMode: Bool {
        switch sendMessageType {
        case .message, .answerMessage:
            return false
        case .editMessage, .editAnswerMessage:
            return true
        }
    }

    var body: some View {
        VStack {
            mentions
            VStack {
                if isFocused && !isEditMode {
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
                if case .editMessage(let message, _) = sendMessageType {
                    viewModel.text = message.content ?? ""
                }
                if case .editAnswerMessage(let answerMessage, _) = sendMessageType {
                    viewModel.text = answerMessage.content ?? ""
                }
            }
            .overlay {
                if isEditMode {
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
    }
}

private extension SendMessageView {
    @ViewBuilder var mentions: some View {
        if let course = conversationViewModel.course.value,
           let presentation = viewModel.presentation {
            switch presentation {
            case .memberPicker:
                SendMessageMentionMemberView(
                    viewModel: SendMessageMentionMemberViewModel(course: course),
                    sendMessageViewModel: viewModel
                )
            case .channelPicker:
                SendMessageMentionChannelView(
                    viewModel: SendMessageMentionChannelViewModel(course: course),
                    sendMessageViewModel: viewModel
                )
            }
        }
    }

    @ViewBuilder var textField: some View {
        if isEditMode {
            TextField(
                R.string.localizable.messageAction(conversationViewModel.conversation.value?.baseConversation.conversationName ?? ""),
                text: $viewModel.text, axis: .vertical
            )
            .textFieldStyle(ArtemisTextField())
        } else {
            TextField(
                R.string.localizable.messageAction(conversationViewModel.conversation.value?.baseConversation.conversationName ?? ""),
                text: $viewModel.text, axis: .vertical
            )
        }
    }

    var keyboardToolbarContent: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Button {
                        viewModel.text.append("****")
                    } label: {
                        Image(systemName: "bold")
                    }
                    Button {
                        viewModel.text.append("**")
                    } label: {
                        Image(systemName: "italic")
                    }
                    Button {
                        viewModel.text.append("<ins></ins>")
                    } label: {
                        Image(systemName: "underline")
                    }
                    Button {
                        viewModel.text.append("> Reference")
                    } label: {
                        Image(systemName: "quote.opening")
                    }
                    Button {
                        viewModel.text.append("``")
                    } label: {
                        Image(systemName: "curlybraces")
                    }
                    Button {
                        viewModel.text.append("```java\nSource Code\n```")
                    } label: {
                        Image(systemName: "curlybraces.square.fill")
                    }
                    Button {
                        viewModel.text.append("[](http://)")
                    } label: {
                        Image(systemName: "link")
                    }
                    Button(action: viewModel.didTapAtButton) {
                        Image(systemName: "at")
                    }
                    Button(action: viewModel.didTapNumberButton) {
                        Image(systemName: "number")
                    }
                    Button {
                        isFocused = false
                        viewModel.isExercisePickerPresented = true
                    } label: {
                        Text(R.string.localizable.exercise())
                    }
                    .sheet(isPresented: $viewModel.isExercisePickerPresented) {
                        isFocused = true
                    } content: {
                        if let course = conversationViewModel.course.value {
                            SendMessageExercisePicker(text: $viewModel.text, course: course)
                        } else {
                            Text(R.string.localizable.loading())
                        }
                    }
                    Button {
                        isFocused = false
                        viewModel.isLecturePickerPresented = true
                    } label: {
                        Text(R.string.localizable.lecture())
                    }
                    .sheet(isPresented: $viewModel.isLecturePickerPresented) {
                        isFocused = true
                    } content: {
                        if let course = conversationViewModel.course.value {
                            SendMessageLecturePicker(text: $viewModel.text, course: course)
                        } else {
                            Text(R.string.localizable.loading())
                        }
                    }
                }
            }
            Spacer()
            sendButton
        }
    }

    var sendButton: some View {
        Button {
            conversationViewModel.isLoading = true
            Task {
                var result: NetworkResponse?
                switch sendMessageType {
                case .message:
                    result = await conversationViewModel.sendMessage(text: viewModel.text)
                case let .answerMessage(message, completion):
                    result = await conversationViewModel.sendAnswerMessage(text: viewModel.text, for: message, completion: completion)
                case let .editMessage(message, completion):
                    var newMessage = message
                    newMessage.content = viewModel.text
                    let success = await conversationViewModel.editMessage(message: newMessage)
                    conversationViewModel.isLoading = false
                    if success {
                        completion()
                    }
                case let .editAnswerMessage(message, completion):
                    var newMessage = message
                    newMessage.content = viewModel.text
                    let success = await conversationViewModel.editAnswerMessage(answerMessage: newMessage)
                    conversationViewModel.isLoading = false
                    if success {
                        completion()
                    }
                }
                switch result {
                case .success:
                    viewModel.text = ""
                default:
                    return
                }
            }
        } label: {
            Image(systemName: "paperplane.fill")
                .imageScale(.large)
        }
        .padding(.leading, .l)
        .disabled(viewModel.text.isEmpty)
        .loadingIndicator(isLoading: $conversationViewModel.isLoading)
    }
}
