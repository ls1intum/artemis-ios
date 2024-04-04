//
//  SendMessageView.swift
//
//
//  Created by Sven Andabaka on 08.04.23.
//

import Common
import DesignLibrary
import SharedModels
import SwiftUI

struct SendMessageView: View {

    @State var isAddContentPresented = false

    @State var viewModel: SendMessageViewModel

    @FocusState private var isFocused: Bool

    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isEditing {
                Spacer()
            } else {
                Divider()
            }

            mentions
            if isFocused && !viewModel.isEditing {
                Capsule()
                    .fill(Color.secondary)
                    .frame(width: .xl, height: .s)
                    .padding(.vertical, .m)
            }
            textField
                .padding(isFocused ? [.horizontal, .bottom] : .all, .l)
        }
        .onAppear {
            viewModel.performOnAppear()
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
                        let impactMed = UIImpactFeedbackGenerator(style: .medium)
                        impactMed.impactOccurred()
                    }
                }
        )
        .sheet(item: $viewModel.modalPresentation) {
            isFocused = true
        } content: { presentation in
            switch presentation {
            case .exercisePicker:
                SendMessageExercisePicker(text: $viewModel.text, course: viewModel.course)
            case .lecturePicker:
                SendMessageLecturePicker(text: $viewModel.text, course: viewModel.course)
            }
        }
        .sheet(isPresented: $isAddContentPresented) {
            NavigationStack {
                List {
                    NavigationLink {
                        ContentUnavailableView(R.string.localizable.exercisesUnavailable(), systemImage: "magnifyingglass")
                    } label: {
                        Label("Exercises", systemImage: "list.bullet.clipboard")
                    }
                    NavigationLink {
                        ContentUnavailableView(R.string.localizable.lecturesUnavailable(), systemImage: "magnifyingglass")
                    } label: {
                        Label("Lectures", systemImage: "character.book.closed")
                    }
                }
                .listStyle(.plain)
            }
            .presentationDetents([.fraction(0.5), .medium])
        }
    }
}

@MainActor
private extension SendMessageView {
    @ViewBuilder var mentions: some View {
        if let presentation = viewModel.conditionalPresentation {
            VStack(spacing: 0) {
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
                if !viewModel.isEditing {
                    Divider()
                }
            }
        }
    }

    var textField: some View {
        HStack(alignment: .bottom) {
            TextField(
                R.string.localizable.messageAction(viewModel.conversation.baseConversation.conversationName),
                text: $viewModel.text,
                axis: .vertical
            )
            .textFieldStyle(.roundedBorder)
            .lineLimit(10)
            .focused($isFocused)
            .toolbar {
                ToolbarItem(placement: .keyboard) {
                    keyboardToolbarContent
                }
            }
            if !isFocused {
                sendButton
            }
        }
    }

    var keyboardToolbarContent: some View {
        HStack {
            ScrollView(.horizontal, showsIndicators: false) {
                HStack {
                    Button {
                        isAddContentPresented.toggle()
                    } label: {
                        Image(systemName: "plus.circle.fill")
                    }
                    Divider()
                    Button {
                        viewModel.didTapBoldButton()
                    } label: {
                        Image(systemName: "bold")
                    }
                    Button {
                        viewModel.didTapItalicButton()
                    } label: {
                        Image(systemName: "italic")
                    }
                    Button {
                        viewModel.didTapUnderlineButton()
                    } label: {
                        Image(systemName: "underline")
                    }
                    Button {
                        viewModel.didTapBlockquoteButton()
                    } label: {
                        Image(systemName: "quote.opening")
                    }
                    Button {
                        viewModel.didTapCodeButton()
                    } label: {
                        Image(systemName: "curlybraces")
                    }
                    Button {
                        viewModel.didTapCodeBlockButton()
                    } label: {
                        Image(systemName: "curlybraces.square.fill")
                    }
                    Button {
                        viewModel.didTapLinkButton()
                    } label: {
                        Image(systemName: "link")
                    }
                    Divider()
                    Button {
                        viewModel.didTapAtButton()
                    } label: {
                        Image(systemName: "at")
                    }
                    Button {
                        viewModel.didTapNumberButton()
                    } label: {
                        Image(systemName: "number")
                    }
//                    Button {
//                        isFocused = false
//                        viewModel.modalPresentation = .exercisePicker
//                    } label: {
//                        Text(R.string.localizable.exercise())
//                    }
//                    Button {
//                        isFocused = false
//                        viewModel.modalPresentation = .lecturePicker
//                    } label: {
//                        Text(R.string.localizable.lecture())
//                    }
                }
            }
            Spacer()
            sendButton
        }
    }

    var sendButton: some View {
        Button(action: viewModel.didTapSendButton) {
            Image(systemName: "paperplane.fill")
                .imageScale(.large)
        }
        .padding(.leading, .l)
        .disabled(viewModel.text.isEmpty)
        .loadingIndicator(isLoading: $viewModel.isLoading)
    }
}
