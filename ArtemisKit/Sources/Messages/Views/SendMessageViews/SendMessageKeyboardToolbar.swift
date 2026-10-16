//
//  SendMessageKeyboardToolbar.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 31.08.25.
//

import Navigation
import SwiftUI

struct SendMessageKeyboardToolbar<SendButton: View>: View {
    @Environment(\.availableTabs) private var tabs

    let sendButton: SendButton
    @Bindable var viewModel: SendMessageViewModel

    let uploadFileViewModel: SendMessageUploadFileViewModel
    let uploadImageViewModel: SendMessageUploadImageViewModel

    var body: some View {
        VStack(spacing: .s) {
            HStack(spacing: .m) {
                formatButton(R.string.localizable.bold(), icon: "bold", style: .bold)
                formatButton(R.string.localizable.italic(), icon: "italic", style: .italic)
                Button(action: viewModel.didTapLinkButton) {
                    Label(R.string.localizable.link(), systemImage: "link")
                }
                .disabled(!viewModel.editor.canSetLink)
                Button(action: viewModel.didTapAtButton) {
                    Label(R.string.localizable.members(), systemImage: "at")
                }
                Button(action: viewModel.didTapNumberButton) {
                    Label(R.string.localizable.channels(), systemImage: "number")
                }
                Button {
                    withAnimation { viewModel.formattingExpanded.toggle() }
                } label: {
                    Label(R.string.localizable.moreFormatting(), systemImage: viewModel.formattingExpanded ? "chevron.up" : "ellipsis")
                }
                .accessibilityValue(viewModel.formattingExpanded ? R.string.localizable.expanded() : R.string.localizable.collapsed())
                Spacer(minLength: 0)
                sendButton
            }
            if viewModel.formattingExpanded {
                HStack(spacing: .l) {
                    formatButton(R.string.localizable.underline(), icon: "underline", style: .underline)
                    formatButton(R.string.localizable.strikethrough(), icon: "strikethrough", style: .strikethrough)
                    formatButton(R.string.localizable.inlineCode(), icon: "curlybraces", style: .code)
                    mentionContentMenu
                    Menu {
                        SendMessageImagePickerView(viewModel: uploadImageViewModel)
                        SendMessageFilePickerView(viewModel: uploadFileViewModel)
                    } label: {
                        Label(R.string.localizable.attachments(), systemImage: "paperclip")
                    }
                    Spacer(minLength: 0)
                    Button {
                        withAnimation { viewModel.editorExpanded.toggle() }
                    } label: {
                        Label(R.string.localizable.resizeEditor(), systemImage: viewModel.editorExpanded ? "arrow.down.right.and.arrow.up.left" : "arrow.up.left.and.arrow.down.right")
                    }
                }
                .padding(.top, .s)
            }
        }
        .labelStyle(.iconOnly)
        .font(.body)
        .buttonStyle(.borderless)
        .padding(.horizontal, .l)
        .padding(.vertical, .m)
    }

    private func formatButton(_ label: String, icon: String, style: MessageEditorStyle) -> some View {
        Button {
            viewModel.editor.toggle(style)
        } label: {
            Label(label, systemImage: icon)
                .frame(minWidth: 28, minHeight: 28)
                .background(viewModel.editor.activeStyle.contains(style) ? Color.accentColor.opacity(0.15) : Color.clear, in: .rect(cornerRadius: 4))
        }
        .disabled(viewModel.editor.isSourceFallback)
        .accessibilityAddTraits(viewModel.editor.activeStyle.contains(style) ? .isSelected : [])
    }

    var mentionContentMenu: some View {
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
            if tabs.faq {
                Button {
                    viewModel.wantsToAddMessageMentionContentType = .faq
                } label: {
                    Label(R.string.localizable.faqs(), systemImage: "questionmark.circle")
                }
            }
        } label: {
            Label(R.string.localizable.mention(), systemImage: "plus.circle.fill")
        }
    }
}
