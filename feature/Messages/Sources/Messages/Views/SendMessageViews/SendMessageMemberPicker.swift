//
//  SendMessageMemberPicker.swift
//
//
//  Created by Nityananda Zbil on 28.10.23.
//

import SharedModels
import SwiftUI

struct SendMessageMemberPicker: View {

    @Environment(\.dismiss) var dismiss

    @StateObject private var viewModel: SendMessageMemberPickerModel

    @Binding var text: String

    init(course: Course, conversation: Conversation, text: Binding<String>) {
        self._viewModel = StateObject(wrappedValue: SendMessageMemberPickerModel(course: course, conversation: conversation))
        self._text = text
    }

    var body: some View {
        Group {
            if !viewModel.members.isEmpty {
                List {
                    ForEach(viewModel.members) { member in
                        if let login = member.login, let name = member.name {
                            Button(name) {
                                text.append("[user]\(name)(\(login))[/user]")
                                dismiss()
                            }
                        }
                    }
                    if viewModel.isMoreDataAvailable {
                        lastRowView
                    }
                }
            } else {
                ContentUnavailableView(R.string.localizable.membersUnavailable(), systemImage: "magnifyingglass")
            }
        }
        .task {
            await viewModel.loadMoreItems()
        }
    }

    var lastRowView: some View {
        ZStack(alignment: .center) {
            switch viewModel.paginationState {
            case .loading:
                ProgressView()
            case .done:
                EmptyView()
            case .failure(let error):
                Text(error.title)
            }
        }
        .frame(height: 50)
        .task {
            await viewModel.loadMoreItems()
        }
    }
}
