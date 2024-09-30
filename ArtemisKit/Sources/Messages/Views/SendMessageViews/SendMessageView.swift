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
        VStack(spacing: 0) {
            if viewModel.isEditing {
                Spacer()
            } else {
                Divider()
            }

            mentions
            if isFocused && !viewModel.isEditing {
                Capsule()
                    .fill(Color.secondary)
                    .frame(width: .xl, height: .s)
                    .padding(.vertical, .m)
            }
            textField
                .padding(isFocused ? [.horizontal, .bottom] : .all, .l)
            if isFocused {
                keyboardToolbarContent
                    .padding(.horizontal, .l)
                    .padding(.vertical, .m)
                    .background(.bar)
            }
        }
        .onAppear {
            viewModel.performOnAppear()
            if viewModel.presentKeyboardOnAppear {
                isFocused = true
            }
        }
        .onDisappear {
            viewModel.performOnDisappear()
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
        .sheet(item: $viewModel.wantsToAddMessageMentionContentType) { type in
            SendMessageMentionContentView(viewModel: viewModel, type: type)
                .presentationDetents([.fraction(0.5), .medium])
        }
    }
}

@MainActor
private extension SendMessageView {
    @ViewBuilder var mentions: some View {
        if let presentation = viewModel.conditionalPresentation {
            VStack(spacing: 0) {
                switch presentation {
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
                }
                if !viewModel.isEditing {
                    Divider()
                }
            }
        }
    }

    var textField: some View {
        HStack(alignment: .bottom) {
            TextField(
                R.string.localizable.messageAction(viewModel.conversation.baseConversation.conversationName),
                text: $viewModel.text,
                axis: .vertical
            )
            .textFieldStyle(.roundedBorder)
            .lineLimit(10)
            .focused($isFocused)
            if !isFocused {
                sendButton
            }
        }
    }

    var keyboardToolbarContent: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(alignment: .firstTextBaseline, spacing: .l) {
                    Menu {
                        Button {
                            viewModel.didTapAtButton()
                        } label: {
                            Label(R.string.localizable.members(), systemImage: "at")
                        }
                        Button {
                            viewModel.didTapNumberButton()
                        } label: {
                            Label(R.string.localizable.channels(), systemImage: "number")
                        }
                        Button {
                            viewModel.wantsToAddMessageMentionContentType = .exercise
                        } label: {
                            Label(R.string.localizable.exercises(), systemImage: "list.bullet.clipboard")
                        }
                        Button {
                            viewModel.wantsToAddMessageMentionContentType = .lecture
                        } label: {
                            Label(R.string.localizable.lectures(), systemImage: "character.book.closed")
                        }
                    } label: {
                        Label(R.string.localizable.mention(), systemImage: "plus.circle.fill")
                            .labelStyle(.iconOnly)
                    }
                    Menu {
                        Button {
                            viewModel.didTapBoldButton()
                        } label: {
                            Label(R.string.localizable.bold(), systemImage: "bold")
                        }
                        Button {
                            viewModel.didTapItalicButton()
                        } label: {
                            Label(R.string.localizable.italic(), systemImage: "italic")
                        }
                        Button {
                            viewModel.didTapUnderlineButton()
                        } label: {
                            Label(R.string.localizable.underline(), systemImage: "underline")
                        }
                    } label: {
                        Label(R.string.localizable.style(), systemImage: "bold.italic.underline")
                            .labelStyle(.iconOnly)
                    }
                    Button {
                        viewModel.didTapBlockquoteButton()
                    } label: {
                        Label(R.string.localizable.quote(), systemImage: "quote.opening")
                            .labelStyle(.iconOnly)
                    }
                    Menu {
                        Button {
                            viewModel.didTapCodeButton()
                        } label: {
                            Label(R.string.localizable.inlineCode(), systemImage: "curlybraces")
                        }
                        Button {
                            viewModel.didTapCodeBlockButton()
                        } label: {
                            Label(R.string.localizable.codeBlock(), systemImage: "curlybraces.square.fill")
                        }
                    } label: {
                        Label(R.string.localizable.code(), systemImage: "curlybraces")
                            .labelStyle(.iconOnly)
                    }
                    Button {
                        viewModel.didTapLinkButton()
                    } label: {
                        Label(R.string.localizable.link(), systemImage: "link")
                            .labelStyle(.iconOnly)
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
