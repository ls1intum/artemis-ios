//
//  SavedMessageView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 15.03.25.
//

import ArtemisMarkdown
import DesignLibrary
import Navigation
import SharedModels
import SwiftUI

struct SavedMessageView: View {
    let viewModel: SavedMessagesViewModel
    let post: SavedPostDTO

    var body: some View {
        Section {
            NavigationLink {
                let path = ThreadPath(postId: post.referencePostId,
                                      conversation: getConversationForPath(),
                                      coursePath: CoursePath(course: viewModel.course))
                ThreadPathView(path: path)
            } label: {
                VStack(alignment: .leading) {
                    header
                    ArtemisMarkdownView(string: post.content.surroundingMarkdownImagesWithNewlines())
                        .allowsHitTesting(false)
                }
            }
            .listRowInsets(EdgeInsets(top: .m, leading: .m, bottom: .s, trailing: .l))
            .swipeActions(edge: .trailing, allowsFullSwipe: true) {
                Button(R.string.localizable.removeBookmark(), systemImage: "bookmark.slash") {
                    Task {
                        await viewModel.unsave(post: post)
                    }
                }
                .labelStyle(.iconOnly)
                .tint(.red)
            }

            messageActions
        }
        .listRowSeparator(.hidden)
    }

    @ViewBuilder var header: some View {
        HStack(alignment: .top, spacing: .m) {
            ProfilePictureView(user: ConversationUser(id: post.author.id,
                                                      name: post.author.name,
                                                      imageUrl: post.author.imageUrl),
                               role: post.role,
                               course: viewModel.course)
            VStack(alignment: .leading, spacing: .xs) {
                HStack(alignment: .firstTextBaseline) {
                    Text(post.author.name)
                        .bold()
                        .lineLimit(1)
                    Spacer(minLength: .s)
                    Text(post.creationDate, formatter: DateFormatter.superShortDateAndTime)
                        .font(.caption)
                        .offset(x: .m * 1.5)
                }
                conversationName
            }
        }
    }

    @ViewBuilder var conversationName: some View {
        if let name = post.conversation.title {
            let namePrefix = post.conversation.type == .channel ? "#" : ""
            let threadSuffix = post.referencePostId == post.id ? "" : " > \(R.string.localizable.thread())"
            Text("\(namePrefix)\(name)\(threadSuffix)")
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
    }

    var messageActions: some View {
        HStack {
            if viewModel.selectedType != .inProgress {
                Button {
                    Task {
                        await viewModel.updatePostStatus(of: post, to: .inProgress)
                    }
                } label: {
                    Label(R.string.localizable.inProgress(), systemImage: "bookmark")
                        .padding(.vertical, .m)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(.blue.opacity(0.3), in: .rect(cornerRadius: .l))
                }
            }

            if viewModel.selectedType != .completed {
                Button {
                    Task {
                        await viewModel.updatePostStatus(of: post, to: .completed)
                    }
                } label: {
                    Label(R.string.localizable.done(), systemImage: "checkmark")
                        .padding(.vertical, .m)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(.green.opacity(0.3), in: .rect(cornerRadius: .l))
                }
            }

            if viewModel.selectedType != .archived {
                Button {
                    Task {
                        await viewModel.updatePostStatus(of: post, to: .archived)
                    }
                } label: {
                    Label(R.string.localizable.archive(), systemImage: "archivebox")
                        .padding(.vertical, .m)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(.gray.opacity(0.3), in: .rect(cornerRadius: .l))
                }
            }
        }
        .foregroundStyle(.primary)
        .buttonStyle(.plain)
        .listRowInsets(EdgeInsets(top: .s, leading: .m, bottom: .m, trailing: .m))
    }
}

private extension SavedMessageView {
    func getConversationForPath() -> Conversation {
        var conversation = Channel(id: post.conversation.id)
        if post.conversation.type == .channel {
            conversation.name = post.conversation.title
            conversation.isPublic = true
        } else {
            conversation.name = post.conversation.title ?? R.string.localizable.privateChannelLabel()
            conversation.isPublic = false
        }
        return .channel(conversation: conversation)
    }
}
