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
    @EnvironmentObject var navController: NavigationController
    let viewModel: SavedMessagesViewModel
    let post: SavedPostDTO

    var body: some View {
        Section {
            NavigationLink {
                let path = ThreadPath(postId: post.referencePostId,
                                      conversation: .channel(conversation: .init(id: post.conversation.id)),
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

            messageActions
        }
        .listRowSeparator(.hidden)
    }

    @ViewBuilder var header: some View {
        HStack(alignment: .top, spacing: .m) {
            ProfilePictureView(user: ConversationUser(postAuthor: post.author), role: post.role, course: viewModel.course)
            VStack(alignment: .leading, spacing: .xs) {
                HStack(alignment: .firstTextBaseline, spacing: .m) {
                    roleBadge
                    Spacer()
//                    if let creationDate {
//                        Text(creationDate, formatter: .superShortDateAndTime)
//                            .font(.caption)
//                    }
                }
                Text(post.author.name)
                    .bold()
            }
        }
    }

    @ViewBuilder var roleBadge: some View {
        if let authorRole = post.role {
            Chip(
                text: authorRole.displayName,
                backgroundColor: authorRole.badgeColor,
                horizontalPadding: .m,
                verticalPadding: .s
            )
            .font(.footnote)
        }
    }

    var messageActions: some View {
        HStack {
            if viewModel.selectedType != .inProgress {
                Button {
                    // TODO
                } label: {
                    Label("In Progress", systemImage: "bookmark")
                        .padding(.vertical, .m)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(.blue.opacity(0.3), in: .rect(cornerRadius: .l))
                }
            }

            if viewModel.selectedType != .completed {
                Button {
                    // TODO
                } label: {
                    Label("Done", systemImage: "checkmark")
                        .padding(.vertical, .m)
                        .frame(maxWidth: .infinity, alignment: .center)
                        .background(.green.opacity(0.3), in: .rect(cornerRadius: .l))
                }
            }

            if viewModel.selectedType != .archived {
                Button {
                    // TODO
                } label: {
                    Label("Archive", systemImage: "archivebox")
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

// TODO: Move into Core Modules + add image url
extension ConversationUser {
    init(postAuthor: AuthorDTO) {
        self.init(id: postAuthor.id)
        self.name = postAuthor.name
    }
}
