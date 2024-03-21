//
//  SendMessageMentionMemberView.swift
//
//
//  Created by Nityananda Zbil on 28.10.23.
//

import DesignLibrary
import SwiftUI

struct SendMessageMentionMemberView: View {

    @State var viewModel: SendMessageMentionMemberViewModel

    @Bindable var sendMessageViewModel: SendMessageViewModel

    var body: some View {
        DataStateView(data: $viewModel.members) {
            if let candidate = sendMessageViewModel.searchMember().map(String.init) {
                await viewModel.search(loginOrName: candidate)
            }
        } content: { members in
            if !members.isEmpty {
                ScrollView {
                    ForEach(members, id: \.login) { member in
                        HStack {
                            Button {
                                sendMessageViewModel.replace(member: member)
                            } label: {
                                Label(member.name ?? "", systemImage: "at")
                            }
                            .foregroundStyle(.secondary)
                            Spacer()
                        }
                        Divider()
                    }
                }
                .contentMargins(.horizontal, .l, for: .scrollContent)
            } else {
                ContentUnavailableView(R.string.localizable.membersUnavailable(), systemImage: "magnifyingglass")
            }
            Divider()
        }
        .onChange(of: sendMessageViewModel.text, initial: true) {
            search()
        }
    }
}

@MainActor
private extension SendMessageMentionMemberView {
    func search() {
        if let candidate = sendMessageViewModel.searchMember().map(String.init) {
            Task {
                await viewModel.search(loginOrName: candidate)
            }
        }
    }
}
