//
//  SendMessageView.swift
//
//
//  Created by Sven Andabaka on 08.04.23.
//

import ArtemisMarkdown
import Common
import DesignLibrary
import SharedModels
import SwiftUI

struct SendMessageView: View {

    @State var viewModel: SendMessageViewModel
    /// This has to be in here, otherwise it gets deinitialized while file picker is open,
    /// due to the textfield losing focus and the toolbar disappearing
    @State private var uploadFileViewModel: SendMessageUploadFileViewModel
    @State private var uploadImageViewModel: SendMessageUploadImageViewModel

    @FocusState private var isFocused: Bool

    init(viewModel: SendMessageViewModel) {
        self._viewModel = State(initialValue: viewModel)
        self._uploadFileViewModel = State(initialValue: .init(courseId: viewModel.course.id, conversationId: viewModel.conversation.id))
        self._uploadImageViewModel = State(initialValue: .init(courseId: viewModel.course.id, conversationId: viewModel.conversation.id))
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
                .fixedSize(horizontal: false, vertical: true)
                .overlay {
                    preview
                }
                .padding(isFocused ? .horizontal : [.horizontal, .top], .l)
                .padding(.bottom, .m)
            ImageAttachmentsPreview(viewModel: viewModel)
            if isFocused || viewModel.keyboardVisible {
                SendMessageKeyboardToolbar(sendButton: sendButton,
                                           viewModel: viewModel,
                                           uploadFileViewModel: uploadFileViewModel,
                                           uploadImageViewModel: uploadImageViewModel)
                    .background(.bar)
                    .padding(.top, .s)
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
    @ViewBuilder var preview: some View {
        if viewModel.previewVisible {
            ScrollView {
                ArtemisMarkdownView(string: viewModel.text.surroundingMarkdownImagesWithNewlines())
                    .allowsHitTesting(false)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .leading)
            }
            .contentMargins(.s, for: .scrollContent)
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            .background(.background)
            .clipShape(.rect(cornerRadius: .s))
        }
    }

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
            let placeholder = if case .answerMessage = viewModel.configuration {
                R.string.localizable.replyAction()
            } else {
                R.string.localizable.messageAction(conversationName)
            }
            TextField(placeholder,
                      text: $viewModel.text,
                      selection: viewModel.selection,
                      axis: .vertical)
                .textFieldStyle(.roundedBorder)
                .lineLimit(isFocused ? 8 : 5)
                .animation(.smooth, value: isFocused)
                .focused($isFocused)
            if !isFocused {
                sendButton
            }
        }
    }

    var sendButton: some View {
        Button(action: viewModel.didTapSendButton) {
            Image(systemName: "paperplane.fill")
                .imageScale(.large)
        }
        .padding(isFocused ? .trailing : .leading, .l)
        .disabled(!viewModel.canSend)
        .loadingIndicator(isLoading: $viewModel.isLoading)
    }
}
