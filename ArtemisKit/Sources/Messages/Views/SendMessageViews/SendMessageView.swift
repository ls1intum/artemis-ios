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
    @State private var showsEmojiPicker = false
    @State private var restoreFocusAfterEmojiPicker = false
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    init(viewModel: SendMessageViewModel) {
        self._viewModel = State(initialValue: viewModel)
        self._uploadFileViewModel = State(initialValue: .init(courseId: viewModel.course.id, conversationId: viewModel.conversation.id))
        self._uploadImageViewModel = State(initialValue: .init(courseId: viewModel.course.id, conversationId: viewModel.conversation.id))
    }

    var body: some View {
        VStack(spacing: 0) {
            mentions
            VStack(spacing: 0) {
                textField
                    .padding(.horizontal, 8)
                if !viewModel.editor.hasUnsupportedContent {
                    MessageAttachmentsPreview(viewModel: viewModel)
                    SendMessageKeyboardToolbar(sendButton: sendButton,
                                               viewModel: viewModel,
                                               uploadFileViewModel: uploadFileViewModel,
                                               uploadImageViewModel: uploadImageViewModel,
                                               focusEditor: { isFocused = true },
                                               showEmojiPicker: {
                                                   restoreFocusAfterEmojiPicker = isFocused
                                                   isFocused = false
                                                   showsEmojiPicker = true
                                               })
                        .padding(.horizontal, 6)
                }
            }
            .padding(.bottom, 6)
            .background {
                let shape = RoundedRectangle(cornerRadius: 24)
                if reduceTransparency {
                    shape.fill(Color(uiColor: .secondarySystemBackground))
                } else {
                    Color.clear.glassEffect(.regular, in: shape)
                }
            }
            .padding(.horizontal, 12)
            .padding(.vertical, 6)
            .layoutPriority(1)
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
                viewModel.showsLinkEditor = false
                viewModel.wantsToAddMessageMentionContentType = nil
            }
        }
        .onDisappear {
            viewModel.performOnDisappear()
        }
        .sheet(isPresented: $showsEmojiPicker, onDismiss: {
            if restoreFocusAfterEmojiPicker { isFocused = true }
        }) {
            MessageComposerEmojiPicker { emoji in
                viewModel.editor.insertText(emoji)
                restoreFocusAfterEmojiPicker = true
            }
            .presentationDetents([.medium, .large])
        }
        .sheet(isPresented: $viewModel.showsLinkEditor, onDismiss: { isFocused = true }) {
            MessageEditorLinkSheet(editor: viewModel.editor)
                .presentationDetents([.medium])
        }
        .sheet(item: $viewModel.wantsToAddMessageMentionContentType, onDismiss: { isFocused = true }) { type in
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
                // Suggestions yield first when the keyboard or a small window limits space.
                .frame(minHeight: 0, idealHeight: verticalSizeClass == .compact ? 76 : 144,
                       maxHeight: verticalSizeClass == .compact ? 76 : 144)
                .clipped()
                if !viewModel.isEditing {
                    Divider()
                }
            }
        }
    }

    var placeholder: String {
        switch viewModel.configuration {
        case .answerMessage:
            R.string.localizable.replyAction()
        case .forwardMessage:
            R.string.localizable.addMessage()
        default:
            R.string.localizable.messageAction(viewModel.conversation.baseConversation.conversationName)
        }
    }

    var textField: some View {
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
                                      isFocused: $isFocused,
                                      showsCompletions: viewModel.conditionalPresentation != nil)
                    .frame(minHeight: 44)
                    .overlay(alignment: .topLeading) {
                        if viewModel.text.isEmpty {
                            Text(placeholder)
                                .font(.body)
                                .lineLimit(1)
                                .foregroundStyle(Color.primary.opacity(0.6))
                                .padding(.horizontal, 9)
                                .padding(.vertical, 12)
                                .allowsHitTesting(false)
                                .accessibilityHidden(true)
                        }
                    }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    var sendButton: some View {
        Button(action: viewModel.didTapSendButton) {
            ZStack {
                Circle()
                    .fill(viewModel.canSend ? Color.accentColor : Color(uiColor: .tertiarySystemFill))
                if viewModel.isLoading {
                    ProgressView().tint(.white)
                } else {
                    Image(systemName: "arrow.up")
                        .font(.system(size: 19, weight: .semibold))
                        .foregroundStyle(viewModel.canSend ? Color.white : Color.secondary)
                }
            }
            .frame(width: 36, height: 36)
            .frame(width: 44, height: 44)
            .contentShape(.rect)
        }
        .buttonStyle(.plain)
        .keyboardShortcut(.return, modifiers: .command)
        .accessibilityLabel(R.string.localizable.sendMessage())
        .accessibilityIdentifier("message-send")
        .disabled(!viewModel.canSend || viewModel.isLoading)
    }
}
