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
    /// This has to be in here, otherwise it gets deinitialized while file picker is open,
    /// due to the textfield losing focus and the toolbar disappearing
    @State private var uploadFileViewModel: SendMessageUploadFileViewModel

    @FocusState private var isFocused: Bool

    init(viewModel: SendMessageViewModel) {
        self._viewModel = State(initialValue: viewModel)
        self._uploadFileViewModel = State(initialValue: .init(courseId: viewModel.course.id, conversationId: viewModel.conversation.id))
    }

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isEditing {
                Spacer()
            } else {
                Divider()
            }

            if case .forwardMessage = viewModel.configuration {
                Text(R.string.localizable.addMessage())
                    .fontWeight(.semibold)
                    .padding(.horizontal, .l)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.bottom, isFocused ? .m : .m * -1)
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
            if isFocused || viewModel.keyboardVisible {
                keyboardToolbarContent
                    .padding(.horizontal, .l)
                    .padding(.vertical, .m)
                    .background(.bar)
            }
        }
        .onChange(of: isFocused, initial: true) {
            // Don't set keyboardVisible to false automatically on iPad
            // Focus with hardware keyboard is messed up, this is a workaround
            if UIDevice.current.userInterfaceIdiom != .pad || isFocused {
                viewModel.keyboardVisible = isFocused
            }
        }
        .onChange(of: viewModel.text) { oldValue, newValue in
            // Only call change handler if text was entered, not when text was removed
            guard newValue.count > oldValue.count else { return }
            viewModel.handleListFormatting(newValue)
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
                        viewModel.keyboardVisible = false
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
            let conversationName = viewModel.isEditing ? "" : viewModel.conversation.baseConversation.conversationName
            TextField(
                R.string.localizable.messageAction(conversationName),
                text: $viewModel.text,
                selection: viewModel.selection,
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
                        if viewModel.course.faqEnabled == true {
                            Button {
                                viewModel.wantsToAddMessageMentionContentType = .faq
                            } label: {
                                Label(R.string.localizable.faqs(), systemImage: "questionmark.circle")
                            }
                        }
                    } label: {
                        Label(R.string.localizable.mention(), systemImage: "plus.circle.fill")
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
                        Button {
                            viewModel.didTapStrikethroughButton()
                        } label: {
                            Label(R.string.localizable.strikethrough(), systemImage: "strikethrough")
                        }
                    } label: {
                        Label(R.string.localizable.style(), systemImage: "bold.italic.underline")
                    }
                    Menu {
                        Button {
                            viewModel.insertListPrefix(unordered: true)
                        } label: {
                            Label(R.string.localizable.unorderedList(), systemImage: "list.bullet")
                        }
                        Button {
                            viewModel.insertListPrefix(unordered: false)
                        } label: {
                            Label(R.string.localizable.orderedList(), systemImage: "list.number")
                        }
                    } label: {
                        Label(R.string.localizable.listFormatting(), systemImage: "list.triangle")
                    }
                    Button {
                        viewModel.didTapBlockquoteButton()
                    } label: {
                        Label(R.string.localizable.quote(), systemImage: "quote.opening")
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
                    }
                    Button {
                        viewModel.didTapLinkButton()
                    } label: {
                        Label(R.string.localizable.link(), systemImage: "link")
                    }
                    SendMessageImagePickerView(sendMessageViewModel: viewModel)
                    SendMessageFilePickerView(sendViewModel: viewModel, viewModel: uploadFileViewModel)
                }
                .labelStyle(.iconOnly)
                .font(.title3)
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
        .disabled(!viewModel.canSend)
        .loadingIndicator(isLoading: $viewModel.isLoading)
    }
}
