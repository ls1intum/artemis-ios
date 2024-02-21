//
//  SendMessageMemberPicker.swift
//
//
//  Created by Nityananda Zbil on 28.10.23.
//

import DesignLibrary
import SharedModels
import SwiftUI

/// Matches the last 'at' symbol followed by a candidate.
/// The candidate is a possible username or login.
enum SendMessageMemberCandidate {

    private static let regex = #/@(?<candidate>[\w]*)/#

    static func search(text: String) -> Substring? {
        let matches = text.matches(of: regex)
        return matches.last?.candidate
    }

    static func replace(text: inout String, member: UserNameAndLoginDTO) {
        guard let candidate = search(text: text),
              let name = member.name, let login = member.login
        else {
            return
        }

        // Replaces all occurrences. Otherwise, we need to get the match.
        let range = Range<String.Index>?.none

        text = text.replacingOccurrences(
            of: "@" + candidate,
            with: "[user]\(name)(\(login))[/user]",
            range: range)
    }
}

struct SendMessageMemberPicker: View {

    @State private var viewModel: SendMessageMemberPickerModel

    @Binding var text: String

    init(course: Course, conversation: Conversation, text: Binding<String>) {
        self.viewModel = SendMessageMemberPickerModel(course: course, conversation: conversation)
        self._text = text
    }

    var body: some View {
        HStack {
            Spacer()
            DataStateView(data: $viewModel.members) {
                if let candidate = SendMessageMemberCandidate.search(text: text).map(String.init) {
                    await viewModel.search(loginOrName: candidate)
                }
            } content: { members in
                if !members.isEmpty {
                    List {
                        ForEach(members, id: \.login) { member in
                            Button(member.name ?? "") {
                                SendMessageMemberCandidate.replace(text: &text, member: member)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(R.string.localizable.membersUnavailable(), systemImage: "magnifyingglass")
                }
            }
            .onAppear(perform: search)
            .onChange(of: text, search)
            Spacer()
        }
    }
}

private extension SendMessageMemberPicker {
    func search() {
        if let candidate = SendMessageMemberCandidate.search(text: text).map(String.init) {
            Task {
                await viewModel.search(loginOrName: candidate)
            }
        }
    }
}
