//
//  SendMessageChannelPicker.swift
//
//
//  Created by Nityananda Zbil on 02.12.23.
//

import DesignLibrary
import SharedModels
import SwiftUI

enum SendMessageChannelCandidate {

    /// `regex` matches a prefix and the last at symbol followed by a candidate. The candidate is a possible user name
    /// or login.
    private static let regex = #/(?<prefix>[^@]*)@(?<candidate>.*)/#

    static func search(text: String) -> Substring? {
        text.wholeMatch(of: regex)?.candidate
    }

    static func replace(text: inout String, member: UserNameAndLoginDTO) {
        guard let name = member.name, let login = member.login else {
            return
        }
        text.replace(regex) { match in
            match.prefix + "[user]\(name)(\(login))[/user]"
        }
    }
}

struct SendMessageChannelPicker: View {

    @StateObject private var viewModel: SendMessageMemberPickerModel

    @Binding var text: String

    init(course: Course, conversation: Conversation, text: Binding<String>) {
        self._viewModel = StateObject(wrappedValue: SendMessageMemberPickerModel(course: course, conversation: conversation))
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

private extension SendMessageChannelPicker {
    func search() {
        if let candidate = SendMessageMemberCandidate.search(text: text).map(String.init) {
            Task {
                await viewModel.search(loginOrName: candidate)
            }
        }
    }
}
