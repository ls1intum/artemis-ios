//
//  SendMessageKeyboardToolbar.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 31.08.25.
//

import Navigation
import SharedModels
import SwiftUI

struct SendMessageKeyboardToolbar<SendButton: View>: View {
    @Environment(\.availableTabs) private var tabs
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    let sendButton: SendButton
    @Bindable var viewModel: SendMessageViewModel

    let uploadFileViewModel: SendMessageUploadFileViewModel
    let uploadImageViewModel: SendMessageUploadImageViewModel

    var body: some View {
        Group {
            if verticalSizeClass == .compact {
                ScrollView(.horizontal) { toolbarContent }
                    .scrollIndicators(.hidden)
            } else {
                toolbarContent
            }
        }
        .labelStyle(.iconOnly)
        .font(.body)
        .buttonStyle(.borderless)
        .padding(.horizontal, .m)
        .disabled(viewModel.editor.hasUnsupportedContent)
    }

    private var toolbarContent: some View {
        let layout = verticalSizeClass == .compact ? AnyLayout(HStackLayout(spacing: 0)) : AnyLayout(VStackLayout(spacing: 0))
        return layout {
            HStack(spacing: 0) {
                Menu {
                    formatButton(R.string.localizable.bold(), icon: "bold", style: .bold)
                    formatButton(R.string.localizable.italic(), icon: "italic", style: .italic)
                    formatButton(R.string.localizable.underline(), icon: "underline", style: .underline)
                    formatButton(R.string.localizable.strikethrough(), icon: "strikethrough", style: .strikethrough)
                } label: {
                    toolbarLabel(R.string.localizable.textFormatting(), icon: "textformat")
                }
                Button(action: viewModel.didTapLinkButton) {
                    toolbarLabel(R.string.localizable.link(), icon: "link")
                }
                .disabled(!viewModel.editor.canSetLink)
                Menu {
                    formatButton(R.string.localizable.inlineCode(), icon: "curlybraces", style: .code)
                    blockMenuButton(R.string.localizable.codeBlock(), icon: "chevron.left.forwardslash.chevron.right", style: .codeBlock)
                } label: {
                    toolbarLabel(R.string.localizable.code(), icon: "curlybraces")
                }
                .accessibilityIdentifier("message-code-menu")
                Menu {
                    blockMenuButton(R.string.localizable.unorderedList(), icon: "list.bullet", style: .bulletList)
                    blockMenuButton(R.string.localizable.orderedList(), icon: "list.number", style: .numberedList)
                } label: {
                    toolbarLabel(R.string.localizable.lists(), icon: "list.bullet")
                }
                .accessibilityIdentifier("message-lists-menu")
                Button {
                    withAnimation { viewModel.formattingExpanded.toggle() }
                } label: {
                    toolbarLabel(R.string.localizable.moreFormatting(), icon: viewModel.formattingExpanded ? "chevron.up" : "ellipsis")
                }
                .accessibilityValue(viewModel.formattingExpanded ? R.string.localizable.expanded() : R.string.localizable.collapsed())
                Spacer(minLength: 0)
                sendButton
            }
            if viewModel.formattingExpanded {
                HStack(spacing: 0) {
                    blockButton(R.string.localizable.quote(), icon: "text.quote", style: .quote)
                    mentionContentMenu
                        .disabled(!viewModel.editor.canFormatInline)
                    Menu {
                        SendMessageImagePickerView(viewModel: uploadImageViewModel)
                        SendMessageFilePickerView(viewModel: uploadFileViewModel)
                    } label: {
                        toolbarLabel(R.string.localizable.attachments(), icon: "paperclip")
                    }
                    .disabled(!viewModel.editor.canFormatInline)
                    Spacer(minLength: 0)
                }
            }
        }
    }

    private func toolbarLabel(_ title: String, icon: String) -> some View {
        Label(title, systemImage: icon)
            .frame(width: 44, height: 44)
            .contentShape(.rect)
    }

    private func formatButton(_ label: String, icon: String, style: MessageEditorStyle) -> some View {
        Toggle(isOn: Binding(get: { viewModel.editor.activeStyle.contains(style) }, set: { _ in viewModel.editor.toggle(style) })) {
            Label(label, systemImage: icon)
        }
        .disabled(!viewModel.editor.canFormatInline)
        .accessibilityAddTraits(viewModel.editor.activeStyle.contains(style) ? .isSelected : [])
    }

    private func blockMenuButton(_ label: String, icon: String, style: MessageEditorBlockStyle) -> some View {
        Toggle(isOn: Binding(get: { viewModel.editor.activeBlockStyle == style }, set: { _ in viewModel.editor.toggleBlock(style) })) {
            Label(label, systemImage: icon)
        }
    }

    private func blockButton(_ label: String, icon: String, style: MessageEditorBlockStyle) -> some View {
        Button {
            viewModel.editor.toggleBlock(style)
        } label: {
            toolbarLabel(label, icon: icon)
                .background(viewModel.editor.activeBlockStyle == style ? Color.accentColor.opacity(0.15) : Color.clear, in: .rect(cornerRadius: 8))
        }
        .accessibilityAddTraits(viewModel.editor.activeBlockStyle == style ? .isSelected : [])
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
            toolbarLabel(R.string.localizable.mention(), icon: "plus.circle.fill")
        }
    }
}
