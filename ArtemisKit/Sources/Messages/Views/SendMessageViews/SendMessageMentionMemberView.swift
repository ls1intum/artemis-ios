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
        HStack {
            Spacer()
            DataStateView(data: $viewModel.members) {
                if let candidate = sendMessageViewModel.searchMember().map(String.init) {
                    await viewModel.search(loginOrName: candidate)
                }
            } content: { members in
                if !members.isEmpty {
                    List {
                        ForEach(members, id: \.login) { member in
                            Button(member.name ?? "") {
                                sendMessageViewModel.replace(member: member)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(R.string.localizable.membersUnavailable(), systemImage: "magnifyingglass")
                }
            }
            .onChange(of: sendMessageViewModel.text, initial: true) {
                search()
            }
            Spacer()
        }
        .listStyle(.plain)
        .clipShape(.rect(cornerRadius: .l))
        .overlay {
            RoundedRectangle(cornerRadius: .l)
                .stroke(Color.Artemis.artemisBlue, lineWidth: 2)
        }
        .padding(.bottom, .m)
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
