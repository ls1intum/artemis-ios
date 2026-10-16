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
    /// Attachment state and presentation outlive the toolbar when a picker takes editor focus.
    @State private var uploadFileViewModel: SendMessageUploadFileViewModel
    @State private var uploadImageViewModel: SendMessageUploadImageViewModel

    @State private var isFocused = false

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
        .sheet(isPresented: $viewModel.showsLinkEditor) {
            MessageEditorLinkSheet(editor: viewModel.editor)
                .presentationDetents([.medium])
        }
        .sheet(item: $viewModel.wantsToAddMessageMentionContentType) { type in
            SendMessageMentionContentView(viewModel: viewModel, type: type)
                .presentationDetents([.fraction(0.5), .medium])
        }
        .imagePicker(isPresented: $uploadImageViewModel.isImagePickerPresented,
                     selectedImage: $uploadImageViewModel.selection)
        .onChange(of: uploadImageViewModel.selection) {
            uploadImageViewModel.onChange()
        }
        .sheet(isPresented: uploadImageViewModel.showUploadScreen) {
            if let path = uploadImageViewModel.filePath {
                viewModel.insertImageMention(path: path, image: uploadImageViewModel.image)
            }
            uploadImageViewModel.selection = nil
            uploadImageViewModel.image = nil
        } content: {
            UploadFileProgressView(viewModel: uploadImageViewModel)
        }
        .filePicker(isPresented: $uploadFileViewModel.isFilePickerPresented,
                    onFilePicked: uploadFileViewModel.filePicked(at:)) { error in
            uploadFileViewModel.uploadState = .failed(error: .init(title: error.localizedDescription))
        }
        .sheet(isPresented: uploadFileViewModel.showUploadScreen) {
            if let path = uploadFileViewModel.filePath {
                viewModel.insertFileMention(path: path, fileName: uploadFileViewModel.fileName ?? "file")
            }
            uploadFileViewModel.resetFileSelection()
        } content: {
            UploadFileProgressView(viewModel: uploadFileViewModel)
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
            let placeholder = if case .answerMessage = viewModel.configuration {
                R.string.localizable.replyAction()
            } else {
                R.string.localizable.messageAction(conversationName)
            }
            VStack(alignment: .leading, spacing: .s) {
                if viewModel.editor.isSourceFallback {
                    Text(R.string.localizable.legacyMarkdownEditor())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                MessageRichTextEditor(document: viewModel.editor, placeholder: placeholder,
                                      isFocused: $isFocused, expanded: viewModel.editorExpanded)
                    .overlay(alignment: .topLeading) {
                        if viewModel.text.isEmpty {
                            Text(placeholder)
                                .foregroundStyle(.tertiary)
                                .padding(.horizontal, 8)
                                .padding(.vertical, 8)
                                .allowsHitTesting(false)
                        }
                    }
            }
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
        .keyboardShortcut(.return, modifiers: .command)
        .padding(isFocused ? .trailing : .leading, .l)
        .disabled(!viewModel.canSend)
        .loadingIndicator(isLoading: $viewModel.isLoading)
    }
}
