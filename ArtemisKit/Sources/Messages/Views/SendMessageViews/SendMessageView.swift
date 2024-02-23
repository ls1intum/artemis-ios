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

    @ObservedObject var viewModel: ConversationViewModel

    @State var sendMessageViewModel = SendMessageViewModel()

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
            pickers
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
                    sendMessageViewModel.text = message.content ?? ""
                }
                if case .editAnswerMessage(let answerMessage, _) = sendMessageType {
                    sendMessageViewModel.text = answerMessage.content ?? ""
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
    @ViewBuilder var pickers: some View {
        if let course = viewModel.course.value,
           let conversation = viewModel.conversation.value {
            switch sendMessageViewModel.presentation {
            case .memberPicker:
                SendMessageMemberPicker(
                    viewModel: SendMessageMemberPickerModel(course: course),
                    sendMessageViewModel: sendMessageViewModel
                )
            case .channelPicker:
                SendMessageChannelPickerView(
                    viewModel: SendMessageChannelPickerViewModel(course: course, conversation: conversation),
                    sendMessageViewModel: sendMessageViewModel
                )
            case nil:
                EmptyView()
            }
        }
    }

    @ViewBuilder var textField: some View {
        if isEditMode {
            TextField(R.string.localizable.messageAction(viewModel.conversation.value?.baseConversation.conversationName ?? ""),
                      text: $sendMessageViewModel.text, axis: .vertical)
            .textFieldStyle(ArtemisTextField())
        } else {
            TextField(R.string.localizable.messageAction(viewModel.conversation.value?.baseConversation.conversationName ?? ""),
                      text: $sendMessageViewModel.text, axis: .vertical)
        }
    }

    var keyboardToolbarContent: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Button {
                        sendMessageViewModel.text.append("****")
                    } label: {
                        Image(systemName: "bold")
                    }
                    Button {
                        sendMessageViewModel.text.append("**")
                    } label: {
                        Image(systemName: "italic")
                    }
                    Button {
                        sendMessageViewModel.text.append("<ins></ins>")
                    } label: {
                        Image(systemName: "underline")
                    }
                    Button {
                        sendMessageViewModel.text.append("> Reference")
                    } label: {
                        Image(systemName: "quote.opening")
                    }
                    Button {
                        sendMessageViewModel.text.append("``")
                    } label: {
                        Image(systemName: "curlybraces")
                    }
                    Button {
                        sendMessageViewModel.text.append("```java\nSource Code\n```")
                    } label: {
                        Image(systemName: "curlybraces.square.fill")
                    }
                    Button {
                        sendMessageViewModel.text.append("[](http://)")
                    } label: {
                        Image(systemName: "link")
                    }
                    Button("At", systemImage: "at", action: sendMessageViewModel.didTapAtButton)
                    Button("Number", systemImage: "number", action: sendMessageViewModel.didTapNumberButton)
                    Button {
                        isFocused = false
                        sendMessageViewModel.isExercisePickerPresented = true
                    } label: {
                        Text(R.string.localizable.exercise())
                    }
                    .sheet(isPresented: $sendMessageViewModel.isExercisePickerPresented) {
                        isFocused = true
                    } content: {
                        if let course = viewModel.course.value {
                            SendMessageExercisePicker(text: $sendMessageViewModel.text, course: course)
                        } else {
                            Text(R.string.localizable.loading())
                        }
                    }
                    Button {
                        isFocused = false
                        sendMessageViewModel.isLecturePickerPresented = true
                    } label: {
                        Text(R.string.localizable.lecture())
                    }
                    .sheet(isPresented: $sendMessageViewModel.isExercisePickerPresented) {
                        isFocused = true
                    } content: {
                        if let course = viewModel.course.value {
                            SendMessageLecturePicker(text: $sendMessageViewModel.text, course: course)
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
            viewModel.isLoading = true
            Task {
                var result: NetworkResponse?
                switch sendMessageType {
                case .message:
                    result = await viewModel.sendMessage(text: sendMessageViewModel.text)
                case let .answerMessage(message, completion):
                    result = await viewModel.sendAnswerMessage(text: sendMessageViewModel.text, for: message, completion: completion)
                case let .editMessage(message, completion):
                    var newMessage = message
                    newMessage.content = sendMessageViewModel.text
                    let success = await viewModel.editMessage(message: newMessage)
                    viewModel.isLoading = false
                    if success {
                        completion()
                    }
                case let .editAnswerMessage(message, completion):
                    var newMessage = message
                    newMessage.content = sendMessageViewModel.text
                    let success = await viewModel.editAnswerMessage(answerMessage: newMessage)
                    viewModel.isLoading = false
                    if success {
                        completion()
                    }
                }
                switch result {
                case .success:
                    sendMessageViewModel.text = ""
                default:
                    return
                }
            }
        } label: {
            Image(systemName: "paperplane.fill")
                .imageScale(.large)
        }
        .padding(.leading, .l)
        .disabled(sendMessageViewModel.text.isEmpty)
        .loadingIndicator(isLoading: $viewModel.isLoading)
    }
}
