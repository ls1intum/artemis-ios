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

    @State private var responseText = ""
    @State private var showExercisePicker = false
    @State private var showLecturePicker = false

    @State private var isMemberPickerSuppressed = false
    @State private var isChannelPickerSuppressed = false

    private var isMemberPickerPresented: Bool {
        SendMessageMemberCandidate.search(text: responseText) != nil && !isMemberPickerSuppressed
    }

    private var isChannelPickerPresented: Bool {
        SendMessageChannelCandidate.search(text: responseText) != nil && !isChannelPickerSuppressed
    }

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
            if isMemberPickerPresented,
                let course = viewModel.course.value,
                let conversation = viewModel.conversation.value {
                SendMessageMemberPicker(course: course, conversation: conversation, text: $responseText)
                    .listStyle(.plain)
                    .clipShape(RoundedRectangle(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.Artemis.artemisBlue, lineWidth: 2)
                    }
                    .padding(.bottom, .m)
            }
            if isChannelPickerPresented,
                let course = viewModel.course.value,
                let conversation = viewModel.conversation.value {
                SendMessageChannelPickerView(course: course, conversation: conversation, text: $responseText)
                    .listStyle(.plain)
                    .clipShape(.rect(cornerRadius: 20))
                    .overlay {
                        RoundedRectangle(cornerRadius: 20)
                            .stroke(Color.Artemis.artemisBlue, lineWidth: 2)
                    }
            }
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
                    responseText = message.content ?? ""
                }
                if case .editAnswerMessage(let answerMessage, _) = sendMessageType {
                    responseText = answerMessage.content ?? ""
                }
            }
            .overlay {
                if isEditMode {
                    EmptyView()
                } else {
                    RoundedRectangle(cornerRadius: 20)
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
    @ViewBuilder var textField: some View {
        if isEditMode {
            TextField(R.string.localizable.messageAction(viewModel.conversation.value?.baseConversation.conversationName ?? ""),
                      text: $responseText, axis: .vertical)
            .textFieldStyle(ArtemisTextField())
        } else {
            TextField(R.string.localizable.messageAction(viewModel.conversation.value?.baseConversation.conversationName ?? ""),
                      text: $responseText, axis: .vertical)
        }
    }

    var keyboardToolbarContent: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Button {
                        responseText.append("****")
                    } label: {
                        Image(systemName: "bold")
                    }
                    Button {
                        responseText.append("**")
                    } label: {
                        Image(systemName: "italic")
                    }
                    Button {
                        responseText.append("<ins></ins>")
                    } label: {
                        Image(systemName: "underline")
                    }
                    Button {
                        responseText.append("> Reference")
                    } label: {
                        Image(systemName: "quote.opening")
                    }
                    Button {
                        responseText.append("``")
                    } label: {
                        Image(systemName: "curlybraces")
                    }
                    Button {
                        responseText.append("```java\nSource Code\n```")
                    } label: {
                        Image(systemName: "curlybraces.square.fill")
                    }
                    Button {
                        responseText.append("[](http://)")
                    } label: {
                        Image(systemName: "link")
                    }
                    Button {
                        if isMemberPickerPresented {
                            isMemberPickerSuppressed = true
                        } else {
                            isMemberPickerSuppressed = false
                            responseText += "@"
                        }
                    } label: {
                        Image(systemName: "at")
                    }
                    Button {
                        if isChannelPickerPresented {
                            isChannelPickerSuppressed = true
                        } else {
                            isChannelPickerSuppressed = false
                            responseText += "#"
                        }
                    } label: {
                        Image(systemName: "number")
                    }
                    Button {
                        isFocused = false
                        showExercisePicker = true
                    } label: {
                        Text(R.string.localizable.exercise())
                    }
                    .sheet(isPresented: $showExercisePicker) {
                        isFocused = true
                    } content: {
                        if let course = viewModel.course.value {
                            SendMessageExercisePicker(text: $responseText, course: course)
                        } else {
                            Text(R.string.localizable.loading())
                        }
                    }
                    Button {
                        isFocused = false
                        showLecturePicker = true
                    } label: {
                        Text(R.string.localizable.lecture())
                    }
                    .sheet(isPresented: $showExercisePicker) {
                        isFocused = true
                    } content: {
                        if let course = viewModel.course.value {
                            SendMessageLecturePicker(text: $responseText, course: course)
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
                    result = await viewModel.sendMessage(text: responseText)
                case let .answerMessage(message, completion):
                    result = await viewModel.sendAnswerMessage(text: responseText, for: message, completion: completion)
                case let .editMessage(message, completion):
                    var newMessage = message
                    newMessage.content = responseText
                    let success = await viewModel.editMessage(message: newMessage)
                    viewModel.isLoading = false
                    if success {
                        completion()
                    }
                case let .editAnswerMessage(message, completion):
                    var newMessage = message
                    newMessage.content = responseText
                    let success = await viewModel.editAnswerMessage(answerMessage: newMessage)
                    viewModel.isLoading = false
                    if success {
                        completion()
                    }
                }
                switch result {
                case .success:
                    responseText = ""
                default:
                    return
                }
            }
        } label: {
            Image(systemName: "paperplane.fill")
                .imageScale(.large)
        }
        .padding(.leading, .l)
        .disabled(responseText.isEmpty)
        .loadingIndicator(isLoading: $viewModel.isLoading)
    }
}
