//
//  SendMessageView.swift
//  
//
//  Created by Sven Andabaka on 08.04.23.
//

import SwiftUI

struct SendMessageView: View {

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
