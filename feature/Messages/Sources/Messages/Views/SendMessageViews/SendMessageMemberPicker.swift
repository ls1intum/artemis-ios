//
//  SendMessageMemberPicker.swift
//
//
//  Created by Nityananda Zbil on 28.10.23.
//

import SharedModels
import SwiftUI

struct SendMessageMemberPicker: View {

    enum SearchAndReplaceCandidate {
        static let regex = #/(?<prefix>.*)@(?<candidate>.*?)/#

        static func search(text: String) -> Substring? {
            let match = text.wholeMatch(of: regex)
            let candidate = match?.candidate
            return candidate
        }

        static func replace(text: inout String, member: ConversationUser) {
            guard let name = member.name, let login = member.login else {
                return
            }
            text.replace(regex) { match in
                match.0 + "[user]\(name)(\(login))[/user]"
            }
        }
    }

    @Environment(\.dismiss) var dismiss

    @StateObject private var viewModel: SendMessageMemberPickerModel

    @Binding var text: String

    init(course: Course, conversation: Conversation, text: Binding<String>) {
        self._viewModel = StateObject(wrappedValue: SendMessageMemberPickerModel(course: course, conversation: conversation))
        self._text = text
    }

    var body: some View {
        if !viewModel.conversationMembers.isEmpty || viewModel.page == 0 {
            List {
                ForEach(viewModel.conversationMembers.filter(isMatchingCandidate(member:))) { member in
                    Button(member.name ?? "") {
                        SearchAndReplaceCandidate.replace(text: &text, member: member)
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
}

private extension SendMessageMemberPicker {
    func isMatchingCandidate(member: ConversationUser) -> Bool {
        guard let candidate = SearchAndReplaceCandidate.search(text: text) else {
            return true
        }
        if let name = member.name, name.lowercased().contains(candidate.lowercased()) {
            return true
        }
        if let login = member.login, login.lowercased().contains(candidate.lowercased()) {
            return true
        }
        return false
    }

    var lastRowView: some View {
        ZStack(alignment: .center) {
            HStack {
                Spacer()
                switch viewModel.paginationState {
                case .loading:
                    ProgressView()
                case .done:
                    EmptyView()
                case .failure(let error):
                    Text(error.title)
                }
                Spacer()
            }
        }
        .task {
            await viewModel.loadMoreItems()
        }
    }
}
