//
//  SendMessageView.swift
//
//
//  Created by Sven Andabaka on 08.04.23.
//

import Common
import DesignLibrary
import PhotosUI
import SharedModels
import SwiftUI

struct SendMessageView: View {

    @State var viewModel: SendMessageViewModel
    /// Attachment state and presentation outlive the toolbar when a picker takes editor focus.
    @State private var uploadFileViewModel: SendMessageUploadFileViewModel
    @State private var uploadImageViewModel: SendMessageUploadImageViewModel

    @State private var isFocused = false
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    init(viewModel: SendMessageViewModel) {
        self._viewModel = State(initialValue: viewModel)
        self._uploadFileViewModel = State(initialValue: .init(courseId: viewModel.course.id, conversationId: viewModel.conversation.id))
        self._uploadImageViewModel = State(initialValue: .init(courseId: viewModel.course.id, conversationId: viewModel.conversation.id))
    }

    var body: some View {
        VStack(spacing: 0) {
            if !viewModel.isEditing {
                Divider()
            }

            if case .forwardMessage = viewModel.configuration {
                Text(R.string.localizable.addMessage())
                    .fontWeight(.semibold)
                    .padding(.horizontal, .l)
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding(.top, .m)
            }

            mentions
            textField
                .padding(.horizontal, .l)
                .padding(.vertical, .s)
            if !viewModel.editor.hasUnsupportedContent {
                MessageAttachmentsPreview(viewModel: viewModel)
            }
            if !viewModel.editor.hasUnsupportedContent && (isFocused || viewModel.keyboardVisible) {
                SendMessageKeyboardToolbar(sendButton: sendButton,
                                           viewModel: viewModel,
                                           uploadFileViewModel: uploadFileViewModel,
                                           uploadImageViewModel: uploadImageViewModel)
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
        .onAppear {
            viewModel.performOnAppear()
            if viewModel.presentKeyboardOnAppear && !viewModel.editor.hasUnsupportedContent {
                isFocused = true
            }
        }
        .onChange(of: viewModel.editor.hasUnsupportedContent) {
            if viewModel.editor.hasUnsupportedContent {
                isFocused = false
                viewModel.keyboardVisible = false
                viewModel.showsLinkEditor = false
                viewModel.wantsToAddMessageMentionContentType = nil
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
        .photosPicker(isPresented: $uploadImageViewModel.isImagePickerPresented, selection: $uploadImageViewModel.selection,
                      matching: .images, preferredItemEncoding: .compatible)
        .onChange(of: uploadImageViewModel.selection) {
            uploadImageViewModel.onChange()
        }
        .sheet(isPresented: uploadImageViewModel.showUploadScreen) {
            guard !uploadImageViewModel.isUploading else { return }
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
            guard !uploadFileViewModel.isUploading else { return }
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
                Group {
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
                }
                .frame(height: verticalSizeClass == .compact ? 76 : 144)
                .clipped()
                .layoutPriority(1)
                if !viewModel.isEditing {
                    Divider()
                }
            }
        }
    }

    var textField: some View {
        HStack(alignment: .top, spacing: .s) {
            let conversationName = viewModel.isEditing ? "" : viewModel.conversation.baseConversation.conversationName
            let placeholder = if case .answerMessage = viewModel.configuration {
                R.string.localizable.replyAction()
            } else {
                R.string.localizable.messageAction(conversationName)
            }
            VStack(alignment: .leading, spacing: .s) {
                if viewModel.editor.hasUnsupportedContent {
                    Text(R.string.localizable.unsupportedMessageFormatting())
                        .font(.caption)
                        .foregroundStyle(.secondary)
                        .accessibilityIdentifier("unsupported-message-formatting")
                    if viewModel.canDiscardUnsupportedDraft {
                        Button(R.string.localizable.discardMessageDraft(), role: .destructive, action: viewModel.discardUnsupportedDraft)
                            .accessibilityIdentifier("discard-unsupported-message-draft")
                    }
                } else {
                    MessageRichTextEditor(document: viewModel.editor, placeholder: placeholder,
                                          isFocused: $isFocused, expanded: viewModel.editorExpanded,
                                          showsCompletions: viewModel.conditionalPresentation != nil)
                        .overlay(alignment: .topLeading) {
                            if viewModel.text.isEmpty {
                                Text(placeholder)
                                    .font(.body)
                                    .lineLimit(1)
                                    .foregroundStyle(.tertiary)
                                    .padding(.horizontal, 9)
                                    .padding(.vertical, 12)
                                    .allowsHitTesting(false)
                            }
                        }
                }
            }
            HStack(spacing: 0) {
                if !viewModel.editor.hasUnsupportedContent {
                    Button {
                        withAnimation { viewModel.editorExpanded.toggle() }
                    } label: {
                        Image(systemName: viewModel.editorExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                            .frame(width: 44, height: 44)
                            .contentShape(.rect)
                    }
                    .accessibilityLabel(R.string.localizable.resizeEditor())
                    .accessibilityValue(viewModel.editorExpanded ? R.string.localizable.expanded() : R.string.localizable.collapsed())
                    .accessibilityIdentifier("message-resize-editor")
                }
                if !isFocused && !viewModel.keyboardVisible {
                    sendButton
                }
            }
        }
    }

    var sendButton: some View {
        Button(action: viewModel.didTapSendButton) {
            Image(systemName: "paperplane.fill")
                .imageScale(.large)
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
        .keyboardShortcut(.return, modifiers: .command)
        .accessibilityLabel(R.string.localizable.sendMessage())
        .disabled(!viewModel.canSend)
        .loadingIndicator(isLoading: $viewModel.isLoading)
    }
}
