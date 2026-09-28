//
//  IrisMessageRow.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 28.09.26.
//

import ArtemisMarkdown
import DesignLibrary
import Navigation
import SwiftUI

struct IrisMessageRow: View {
    let message: IrisMessageResponseDTO
    let courseId: Int
    let viewModel: IrisChatViewModel

    private var isUser: Bool {
        message.sender == .user
    }

    private var isCtxSwap: Bool {
        message.sender == .ctxswap
    }

    var body: some View {
        if isCtxSwap {
            if let contextSwitch = message.contextSwitch {
                IrisContextSwitchDivider(info: contextSwitch, courseId: courseId)
            }
        } else if isUser {
            HStack {
                Spacer()
                VStack(alignment: .trailing, spacing: .s) {
                    ForEach(message.content, id: \.id) { block in
                        if let text = block.textContent {
                            ArtemisMarkdownView(string: text)
                                .padding(.m + .xs)
                                .background(Color.Artemis.reactionCapsuleColor)
                                .foregroundStyle(.primary)
                                .clipShape(RoundedRectangle(cornerRadius: 12))
                        }
                    }
                }
                .frame(maxWidth: 300, alignment: .trailing)
            }
        } else {
            VStack(alignment: .leading, spacing: .s) {
                ForEach(message.content, id: \.id) { block in
                    if let text = block.textContent {
                        ArtemisMarkdownView(string: text)
                            .foregroundStyle(.primary)
                    }
                }
                if message.id != nil {
                    MessageActionBar(message: message, viewModel: viewModel)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

// MARK: MessageActionBar

private struct MessageActionBar: View {
    let message: IrisMessageResponseDTO
    let viewModel: IrisChatViewModel
    @State private var didCopy = false

    private var plainText: String {
        message.content.compactMap(\.textContent).joined(separator: "\n\n")
    }

    var body: some View {
        HStack(spacing: .l) {
            Button(R.string.localizable.copyText(),
                   systemImage: didCopy ? "checkmark" : "doc.on.doc") {
                UIPasteboard.general.string = plainText
                didCopy = true
                DispatchQueue.main.asyncAfter(deadline: .now() + 1) { didCopy = false }
            }
            .labelStyle(.iconOnly)

            ShareLink(item: plainText) {
                Label(R.string.localizable.shareMessage(), systemImage: "square.and.arrow.up")
            }
            .labelStyle(.iconOnly)

            Button(R.string.localizable.rateHelpful(),
                   systemImage: message.helpful == true ? "hand.thumbsup.fill" : "hand.thumbsup") {
                if message.helpful != true, let id = message.id {
                    viewModel.rateMessage(messageId: id, helpful: true)
                }
            }
            .labelStyle(.iconOnly)

            Button(R.string.localizable.rateUnhelpful(),
                   systemImage: message.helpful == false ? "hand.thumbsdown.fill" : "hand.thumbsdown") {
                if message.helpful != false, let id = message.id {
                    viewModel.rateMessage(messageId: id, helpful: false)
                }
            }
            .labelStyle(.iconOnly)
        }
        .font(.callout)
        .foregroundStyle(.secondary)
        .buttonStyle(.plain)
        .padding(.top, .s)
    }
}

// MARK: Context Chip

struct IrisContextChip: View {
    let title: String
    let onTap: () -> Void
    let onRemove: () -> Void

    var body: some View {
        HStack(spacing: .s) {
            Text(title)
                .font(.footnote)
                .lineLimit(1)
                .foregroundStyle(.primary)

            Button(action: onRemove) {
                Image(systemName: "xmark")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, .m)
        .padding(.vertical, .s)
        .background(Color.Artemis.reactionCapsuleColor, in: Capsule())
    }
}
