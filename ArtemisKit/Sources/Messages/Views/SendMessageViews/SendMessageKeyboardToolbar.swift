//
//  SendMessageKeyboardToolbar.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 31.08.25.
//

import SwiftUI

struct SendMessageKeyboardToolbar<SendButton: View>: View {
    let sendButton: SendButton
    let viewModel: SendMessageViewModel

    let uploadFileViewModel: SendMessageUploadFileViewModel
    let uploadImageViewModel: SendMessageUploadImageViewModel

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(alignment: .firstTextBaseline, spacing: .l) {
                mentionContentMenu

                InlineExpandableMenu {
                    SendMessageImagePickerView(sendViewModel: viewModel, viewModel: uploadImageViewModel)
                    SendMessageFilePickerView(sendViewModel: viewModel, viewModel: uploadFileViewModel)
                } label: {
                    Label(R.string.localizable.attachments(), systemImage: "paperclip")
                }

                InlineExpandableMenu {
                    textFormatMenu
                    listFormatMenu
                    codeFormatMenu

                    Button {
                        viewModel.didTapLinkButton()
                    } label: {
                        Label(R.string.localizable.link(), systemImage: "link")
                    }
                    Button {
                        viewModel.didTapBlockquoteButton()
                    } label: {
                        Label(R.string.localizable.quote(), systemImage: "quote.opening")
                    }
                } label: {
                    Label(R.string.localizable.textFormatting(), systemImage: "textformat")
                }
            }
            .labelStyle(.iconOnly)
            .font(.title3)
            .padding(.trailing)
        }
        .contentMargins(.horizontal, .l, for: .scrollContent)
        .contentMargins(.vertical, .m, for: .scrollContent)
        .mask {
            LinearGradient(stops: [
                .init(color: .black.opacity(1), location: 0.9),
                .init(color: .black.opacity(0), location: 1)
            ], startPoint: .leading, endPoint: .trailing)
        }
        .safeAreaInset(edge: .trailing) {
            sendButton
        }
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
    }

    var textFormatMenu: some View {
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
    }

    var listFormatMenu: some View {
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
    }

    var codeFormatMenu: some View {
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
    }
}

struct InlineExpandableMenu<Content: View, Label: View>: View {
    @State private var isExpanded = false
    @Namespace private var namespace

    @ViewBuilder var content: () -> Content
    @ViewBuilder var label: () -> Label

    var body: some View {
        if isExpanded {
            HStack(alignment: .firstTextBaseline, spacing: .l) {
                Button("Close", systemImage: "xmark.circle") {
                    withAnimation {
                        isExpanded = false
                    }
                }
                .labelsHidden()
                .opacity(0.7)
                .matchedGeometryEffect(id: "btn", in: namespace)
                .padding(.leading, .l)
                Group(subviews: content()) { subviews in
                    ForEach(Array(subviews.enumerated()), id: \.0) { offset, subview in
                        subview
                        .matchedGeometryEffect(id: offset, in: namespace)
                    }
                }
                // Spacer (0) + spacing (.l) ensures separability to nearby menus
                Spacer().frame(width: 0)
            }
        } else {
            ZStack(alignment: .leading) {
                Group(subviews: content()) { subviews in
                    ForEach(Array(subviews.enumerated()), id: \.0) { offset, subview in
                        subview.disabled(true).opacity(0)
                            .matchedGeometryEffect(id: offset, in: namespace)
                            .accessibilityHidden(true)
                    }
                }
                Button {
                    withAnimation {
                        isExpanded = true
                    }
                } label: {
                    label()
                }
                .matchedGeometryEffect(id: "btn", in: namespace)
            }
        }
    }
}
