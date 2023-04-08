//
//  ConversationView.swift
//  
//
//  Created by Sven Andabaka on 05.04.23.
//

import SwiftUI
import SharedModels
import DesignLibrary

struct ConversationView: View {

    @StateObject private var viewModel: ConversationViewModel

    init(courseId: Int, conversation: Conversation) {
        _viewModel = StateObject(wrappedValue: ConversationViewModel(courseId: courseId, conversation: conversation))
    }

    var body: some View {
        VStack {
            ScrollView {
                VStack(alignment: .leading) {
                    DataStateView(data: $viewModel.dailyMessages,
                                  retryHandler: { await viewModel.loadMessages() }) { dailyMessages in
                        if dailyMessages.isEmpty {
                            Text("There are no messages yet! Write the first message to kickstart this conversation.")
                                .padding(.vertical, .xl)
                        } else {
                            ForEach(dailyMessages.sorted(by: { $0.key < $1.key }), id: \.key) { dailyMessage in
                                ConversationDaySection(day: dailyMessage.key,
                                                       messages: dailyMessage.value)
                            }
                            Spacer()
                        }
                    }
                }
                    .padding(.horizontal, .l)
            }
            SendMessageView(viewModel: viewModel)
        }
            .navigationTitle(viewModel.conversation.baseConversation.conversationName)
            .task {
                await viewModel.loadMessages()
            }
    }
}

private struct SendMessageView: View {

    @ObservedObject var viewModel: ConversationViewModel

    @State private var responseText = ""

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack {
            if isFocused {
                Capsule()
                    .fill(Color.secondary)
                    .frame(width: 50, height: 3)
                    .padding(.top, .m)
                    .gesture(
                        DragGesture(minimumDistance: 0, coordinateSpace: .local)
                            .onEnded({ value in
                                if value.translation.height > 0 {
                                    // down
                                    isFocused = false
                                }
                            })
                    )
            }
            HStack(alignment: .bottom) {
                TextField("Message \(viewModel.conversation.baseConversation.conversationName)", text: $responseText, axis: .vertical)
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
            .overlay(
                RoundedRectangle(cornerRadius: 20)
                    .trim(from: isFocused ? 0.52 : 0.51, to: isFocused ? 0.98 : 0.99)
                    .stroke(Color.Artemis.artemisBlue, lineWidth: 2)
            )
    }

    var keyboardToolbarContent: some View {
        HStack {
            ScrollView(.horizontal) {
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
                        Image(systemName: "quotelevel")
                    })
                    Button(action: {
                        responseText.append("```java\nSource Code\n```")
                    }, label: {
                        Image(systemName: "doc.append")
                    })
                    Button(action: {
                        print("show Picker")
                    }, label: {
                        Text("Exercise")
                    })
                    Button(action: {
                        print("show Picker")
                    }, label: {
                        Text("Lecture")
                    })
                }
            }
            Spacer()
            sendButton
        }
    }

    var sendButton: some View {
        Button(action: {
            Task {
                await viewModel.sendMessage(text: responseText)
            }
        }, label: {
            Image(systemName: "paperplane.fill")
                .imageScale(.large)
        })
            .padding(.leading, .l)
            .disabled(responseText.isEmpty)
    }
}

private struct ConversationDaySection: View {
    let day: Date
    let messages: [Message]

    var body: some View {
        VStack(alignment: .leading) {
            Text(day, formatter: DateFormatter.dateOnly)
                .font(.headline)
            Divider()
            ForEach(messages, id: \.id) { message in
                MessageCell(message: message)
            }
        }
    }
}

private struct MessageCell: View {
    let message: Message

    var body: some View {
        HStack(alignment: .top, spacing: .l) {
            Image(systemName: "person")
                .resizable()
                .scaledToFit()
                .frame(width: 40, height: 40)
                .padding(.top, .s)
            VStack(alignment: .leading, spacing: .m) {
                HStack(alignment: .bottom, spacing: .m) {
                    Text(message.author?.name ?? "")
                        .bold()
                    if let creationDate = message.creationDate {
                        Text(creationDate, formatter: DateFormatter.timeOnly)
                            .font(.caption)
                    }
                }
                Text(message.content ?? "")
            }
            Spacer()
        }
    }
}

extension Date: Identifiable {
    public var id: Date {
        return self
    }
}
