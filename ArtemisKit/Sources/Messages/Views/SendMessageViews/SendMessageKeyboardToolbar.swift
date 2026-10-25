//
//  SendMessageKeyboardToolbar.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 31.08.25.
//

import Navigation
import SharedModels
import SwiftUI

/// Both modes occupy one row. Only the middle scrolls, keeping close and send reachable.
struct SendMessageKeyboardToolbar<SendButton: View>: View {
    @Environment(\.availableTabs) private var tabs
    @Environment(\.accessibilityReduceMotion) private var reduceMotion

    let sendButton: SendButton
    @Bindable var viewModel: SendMessageViewModel
    let uploadFileViewModel: SendMessageUploadFileViewModel
    let uploadImageViewModel: SendMessageUploadImageViewModel
    var focusEditor: () -> Void = {}
    var showEmojiPicker: () -> Void = {}

    var body: some View {
        HStack(spacing: 0) {
            if viewModel.formattingExpanded {
                Button(action: toggleFormatting) {
                    Image(systemName: "xmark")
                        .frame(width: 32, height: 32)
                        .background(Color.accentColor.opacity(0.15), in: .circle)
                        .frame(width: 44, height: 44)
                        .contentShape(.rect)
                }
                .accessibilityLabel(R.string.localizable.hideFormatting())
                .accessibilityIdentifier("message-close-formatting")
            } else {
                addMenu
            }
            ScrollView(.horizontal) {
                HStack(spacing: 0) {
                    if viewModel.formattingExpanded {
                        formattingControls
                    } else {
                        compositionControls
                    }
                }
            }
            .scrollIndicators(.hidden)
            .frame(height: 44)
            .id(viewModel.formattingExpanded)
            sendButton
        }
        .labelStyle(.iconOnly)
        .font(.system(size: 20))
        .buttonStyle(.plain)
        .foregroundStyle(.secondary)
        .disabled(viewModel.editor.hasUnsupportedContent)
    }

    private var compositionControls: some View {
        Group {
            Button(action: toggleFormatting) {
                toolbarLabel(R.string.localizable.textFormatting(), icon: "textformat")
            }
            .accessibilityIdentifier("message-show-formatting")
            Button(action: showEmojiPicker) {
                toolbarLabel(R.string.localizable.emojis(), icon: "face.smiling")
            }
            .disabled(!viewModel.editor.canFormatInline)
            Button {
                focusEditor()
                viewModel.didTapAtButton()
            } label: {
                toolbarLabel(R.string.localizable.members(), icon: "at")
            }
            .disabled(!viewModel.editor.canFormatInline)
            Button {
                focusEditor()
                viewModel.didTapNumberButton()
            } label: {
                toolbarLabel(R.string.localizable.channels(), icon: "number")
            }
            .disabled(!viewModel.editor.canFormatInline)
        }
    }

    private var formattingControls: some View {
        Group {
            formatButton(R.string.localizable.bold(), icon: "bold", style: .bold)
            formatButton(R.string.localizable.italic(), icon: "italic", style: .italic)
            formatButton(R.string.localizable.underline(), icon: "underline", style: .underline)
            formatButton(R.string.localizable.strikethrough(), icon: "strikethrough", style: .strikethrough)
            Button(action: viewModel.didTapLinkButton) {
                toolbarLabel(R.string.localizable.link(), icon: "link", selected: viewModel.editor.linkRange != nil)
            }
            .disabled(!viewModel.editor.canSetLink)
            .accessibilityAddTraits(viewModel.editor.linkRange != nil ? .isSelected : [])
            blockButton(R.string.localizable.orderedList(), icon: "list.number", style: .numberedList)
            blockButton(R.string.localizable.unorderedList(), icon: "list.bullet", style: .bulletList)
            blockButton(R.string.localizable.quote(), icon: "text.quote", style: .quote)
            formatButton(R.string.localizable.inlineCode(), icon: "curlybraces", style: .code)
            blockButton(R.string.localizable.codeBlock(), icon: "chevron.left.forwardslash.chevron.right", style: .codeBlock)
        }
    }

    private var addMenu: some View {
        Menu {
            Section {
                SendMessageImagePickerView(viewModel: uploadImageViewModel)
                SendMessageFilePickerView(viewModel: uploadFileViewModel)
            }
            Section {
                Button(R.string.localizable.exercises(), systemImage: "list.bullet.clipboard") {
                    viewModel.wantsToAddMessageMentionContentType = .exercise
                }
                Button(R.string.localizable.lectures(), systemImage: "character.book.closed") {
                    viewModel.wantsToAddMessageMentionContentType = .lecture
                }
                if tabs.faq {
                    Button(R.string.localizable.faqs(), systemImage: "questionmark.circle") {
                        viewModel.wantsToAddMessageMentionContentType = .faq
                    }
                }
            }
        } label: {
            Image(systemName: "plus")
                .frame(width: 32, height: 32)
                .background(.quaternary, in: .circle)
                .frame(width: 44, height: 44)
                .contentShape(.rect)
        }
        .accessibilityLabel(R.string.localizable.addAttachmentOrReference())
        .accessibilityIdentifier("message-add-attachment")
        .disabled(!viewModel.editor.canFormatInline)
    }

    private func toggleFormatting() {
        focusEditor()
        withAnimation(reduceMotion ? nil : .easeOut(duration: 0.18)) {
            viewModel.formattingExpanded.toggle()
        }
    }

    private func toolbarLabel(_ title: String, icon: String, selected: Bool = false) -> some View {
        Label(title, systemImage: icon)
            .foregroundStyle(selected ? Color.accentColor : Color.secondary)
            .frame(width: 36, height: 32)
            .background(selected ? Color.accentColor.opacity(0.15) : Color.clear, in: .rect(cornerRadius: 8))
            .frame(width: 44, height: 44)
            .contentShape(.rect)
    }

    private func formatButton(_ title: String, icon: String, style: MessageEditorStyle) -> some View {
        let selected = viewModel.editor.activeStyle.contains(style)
        return Button {
            focusEditor()
            viewModel.editor.toggle(style)
        } label: {
            toolbarLabel(title, icon: icon, selected: selected)
        }
        .disabled(!viewModel.editor.canFormatInline)
        .accessibilityAddTraits(selected ? .isSelected : [])
    }

    private func blockButton(_ title: String, icon: String, style: MessageEditorBlockStyle) -> some View {
        let selected = viewModel.editor.activeBlockStyle == style
        return Button {
            focusEditor()
            viewModel.editor.toggleBlock(style)
        } label: {
            toolbarLabel(title, icon: icon, selected: selected)
        }
        .accessibilityAddTraits(selected ? .isSelected : [])
    }
}
