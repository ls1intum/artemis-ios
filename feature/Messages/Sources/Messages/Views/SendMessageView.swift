//
//  SendMessageView.swift
//  
//
//  Created by Sven Andabaka on 08.04.23.
//

import SwiftUI
import DesignLibrary
import Common
import SharedModels

enum SendMessageType {
    case message, answerMessage(Message, () async -> Void), editMessage(Message, () -> Void), editAnswerMessage(AnswerMessage, () -> Void)
}

struct SendMessageView: View {

    @ObservedObject var viewModel: ConversationViewModel

    @State private var responseText = ""
    @State private var showExercisePicker = false
    @State private var showLecturePicker = false
    @State private var showMemberPicker = false

    @FocusState private var isFocused: Bool

    let sendMessageType: SendMessageType

    var isEditMode: Bool {
        switch sendMessageType {
        case .message:
            return false
        case .answerMessage:
            return false
        case .editMessage:
            return true
        case .editAnswerMessage:
            return true
        }
    }

    var body: some View {
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
            .overlay(
                Group {
                    if isEditMode {
                        EmptyView()
                    } else {
                        RoundedRectangle(cornerRadius: 20)
                            .trim(from: isFocused ? 0.52 : 0.51, to: isFocused ? 0.98 : 0.99)
                            .stroke(Color.Artemis.artemisBlue, lineWidth: 2)
                    }
                }
            )
            .gesture(
                DragGesture(minimumDistance: 30, coordinateSpace: .local)
                    .onEnded({ value in
                        if value.translation.height > 0 {
                            // down
                            isFocused = false
                            let impactMed = UIImpactFeedbackGenerator(style: .medium)
                            impactMed.impactOccurred()
                        }
                    })
            )
    }

    var textField: some View {
        Group {
            if isEditMode {
                TextField(R.string.localizable.messageAction(viewModel.conversation.value?.baseConversation.conversationName ?? ""),
                          text: $responseText, axis: .vertical)
                    .textFieldStyle(ArtemisTextField())
            } else {
                TextField(R.string.localizable.messageAction(viewModel.conversation.value?.baseConversation.conversationName ?? ""),
                          text: $responseText, axis: .vertical)
            }
        }
    }

    var keyboardToolbarContent: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Button(action: {
                        responseText.append("****")
                    }, label: {
                        Image(systemName: "bold")
                    })
                    Button(action: {
                        responseText.append("**")
                    }, label: {
                        Image(systemName: "italic")
                    })
                    Button(action: {
                        responseText.append("<ins></ins>")
                    }, label: {
                        Image(systemName: "underline")
                    })
                    Button(action: {
                        responseText.append("> Reference")
                    }, label: {
                        Image(systemName: "quote.opening")
                    })
                    Button(action: {
                        responseText.append("``")
                    }, label: {
                        Image(systemName: "curlybraces")
                    })
                    Button(action: {
                        responseText.append("```java\nSource Code\n```")
                    }, label: {
                        Image(systemName: "curlybraces.square.fill")
                    })
                    Button(action: {
                        responseText.append("[](http://)")
                    }, label: {
                        Image(systemName: "link")
                    })
                    Button {
                        isFocused = false
                        showMemberPicker = true
                    } label: {
                        Image(systemName: "at")
                    }
                    .sheet(isPresented: $showMemberPicker) {
                        isFocused = true
                    } content: {
                        if let course = viewModel.course.value {
                            SendMessageMemberPicker(text: $responseText, course: course)
                        } else {
                            Text(R.string.localizable.loading())
                        }
                    }
                    Button(action: {
                        isFocused = false
                        showExercisePicker = true
                    }, label: {
                        Text(R.string.localizable.exercise())
                    })
                        .sheet(isPresented: $showExercisePicker, onDismiss: { isFocused = true }) {
                            if let course = viewModel.course.value {
                                SendMessageExercisePicker(text: $responseText, course: course)
                            } else {
                                Text(R.string.localizable.loading())
                            }
                        }
                    Button(action: {
                        isFocused = false
                        showLecturePicker = true
                    }, label: {
                        Text(R.string.localizable.lecture())
                    })
                        .sheet(isPresented: $showLecturePicker, onDismiss: { isFocused = true }) {
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
        Button(action: {
            viewModel.isLoading = true
            Task {
                var result: NetworkResponse?
                switch sendMessageType {
                case .message:
                    result = await viewModel.sendMessage(text: responseText)
                case let .answerMessage(message, completion):
                    result = await viewModel.sendAnswerMessage(text: responseText, for: message, completion: completion)
                case let .editMessage(message, completion):
                    var newmessage = message
                    newmessage.content = responseText
                    let success = await viewModel.editMessage(message: newmessage)
                    viewModel.isLoading = false
                    if success {
                        completion()
                    }
                case let .editAnswerMessage(message, completion):
                    var newmessage = message
                    newmessage.content = responseText
                    let success = await viewModel.editAnswerMessage(answerMessage: newmessage)
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
        }, label: {
            Image(systemName: "paperplane.fill")
                .imageScale(.large)
        })
            .padding(.leading, .l)
            .disabled(responseText.isEmpty)
            .loadingIndicator(isLoading: $viewModel.isLoading)
    }
}

private struct SendMessageExercisePicker: View {

    @Environment(\.dismiss) var dismiss

    @Binding var text: String

    let course: Course

    var body: some View {
        if let exercises = course.exercises, !exercises.isEmpty {
            List(exercises) { exercise in
                if let title = exercise.baseExercise.title {
                    Button(title) {
                        appendMarkdown(for: exercise)
                        dismiss()
                    }
                }
            }
        } else {
            ContentUnavailableView(R.string.localizable.exercisesUnavailable(), systemImage: "magnifyingglass")
        }
    }

    func appendMarkdown(for exercise: Exercise) {
        let type: String?
        switch exercise {
        case .fileUpload:
            type = "file-upload"
        case .modeling:
            type = "modeling"
        case .programming:
            type = "programming"
        case .quiz:
            type = "quiz"
        case .text:
            type = "text"
        case .unknown:
            type = nil
        }

        guard let type,
              let title = exercise.baseExercise.title else { return }

        text.append("[\(type)]\(title)(/courses/\(course.id)/exercises/\(exercise.id))[/\(type)]")
    }
}

private struct SendMessageLecturePicker: View {

    @Environment(\.dismiss) var dismiss

    @Binding var text: String

    let course: Course

    var body: some View {
        if let lectures = course.lectures, !lectures.isEmpty {
            List(lectures) { lecture in
                if let title = lecture.title {
                    Button(title) {
                        text.append("[lecture]\(title)(/courses/\(course.id)/lectures/\(lecture.id))[/lecture]")
                        dismiss()
                    }
                }
            }
        } else {
            ContentUnavailableView(R.string.localizable.lecturesUnavailable(), systemImage: "magnifyingglass")
        }
    }
}

private struct SendMessageMemberPicker: View {

    @Environment(\.dismiss) var dismiss

    @Binding var text: String

    let course: Course

    var body: some View {
        if let members = Optional.some([ConversationUser]()), !members.isEmpty {
            List(members) { member in
                if let login = member.login, let name = member.name {
                    Button(name) {
                        text.append("[user]\(name)(\(login))[/user]")
                        dismiss()
                    }
                }
            }
        } else {
            ContentUnavailableView(R.string.localizable.membersUnavailable(), systemImage: "magnifyingglass")
        }
    }
}
