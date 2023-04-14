//
//  MessageCell.swift
//  
//
//  Created by Sven Andabaka on 12.04.23.
//

import SwiftUI
import ArtemisMarkdown
import SharedModels
import Navigation
import Common

struct MessageCell: View {

    @EnvironmentObject var navigationController: NavigationController

    @ObservedObject var viewModel: ConversationViewModel

    @Binding var message: DataState<BaseMessage>

    @State private var showMessageActionSheet = false
    @State private var isPressed = false

    var author: String {
        message.value?.author?.name ?? ""
    }
    var creationDate: Date? {
        message.value?.creationDate
    }
    var content: String {
        message.value?.content ?? ""
    }

    let conversationPath: ConversationPath?
    let showHeader: Bool

    var body: some View {
        HStack(alignment: .top, spacing: .l) {
            Image(systemName: "person")
                .resizable()
                .scaledToFit()
                .frame(width: 30, height: 30)
                .padding(.top, .s)
                .opacity(showHeader ? 1 : 0)
            VStack(alignment: .leading, spacing: .m) {
                if showHeader {
                    HStack(alignment: .bottom, spacing: .m) {
                        Text(author)
                            .bold()
                        if let creationDate {
                            Text(creationDate, formatter: DateFormatter.timeOnly)
                                .font(.caption)
                        }
                    }
                }
                ArtemisMarkdownView(string: content)
                ReactionsView(viewModel: viewModel, message: $message, showEmojiAddButton: false)
                if let message = message.value as? Message,
                   let answerCount = message.answers?.count,
                   let conversationPath,
                   answerCount > 0 {
                    Button(R.string.localizable.replyAction(answerCount)) {
                        if let messagePath = MessagePath(message: self.$message, coursePath: conversationPath.coursePath, conversationPath: conversationPath, conversationViewModel: viewModel) {
                            navigationController.path.append(messagePath)
                        }
                    }
                }
            }.id(message.value?.id)
            Spacer()
        }
            .padding(.horizontal, .l)
            .contentShape(Rectangle())
            .background(isPressed ? Color.Artemis.messsageCellPressed : Color.clear)
            .onTapGesture {
                print("This somehow fixes scrolling...")
            }
            .onLongPressGesture(minimumDuration: 0.1, maximumDistance: 30, perform: {
                let impactMed = UIImpactFeedbackGenerator(style: .heavy)
                impactMed.impactOccurred()
                showMessageActionSheet = true
                isPressed = false
            }, onPressingChanged: { pressed in
                isPressed = pressed
            })
            .sheet(isPresented: $showMessageActionSheet) {
                MessageActionSheet(viewModel: viewModel, message: $message, conversationPath: conversationPath)
                EmptyView()
                    .presentationDetents([.height(350), .large])
            }
    }
}