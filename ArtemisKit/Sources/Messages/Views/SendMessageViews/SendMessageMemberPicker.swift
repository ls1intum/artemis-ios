//
//  SendMessageMemberPicker.swift
//
//
//  Created by Nityananda Zbil on 28.10.23.
//

import DesignLibrary
import SharedModels
import SwiftUI

struct SendMessageMemberPicker: View {

    @State var viewModel: SendMessageMemberPickerModel

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
            .onChange(of: sendMessageViewModel.text, initial: true, search)
            Spacer()
        }
    }
}

private extension SendMessageMemberPicker {
    func search() {
        if let candidate = sendMessageViewModel.searchMember().map(String.init) {
            Task {
                await viewModel.search(loginOrName: candidate)
            }
        }
    }
}
