//
//  SendMessageMentionChannelView.swift
//
//
//  Created by Nityananda Zbil on 02.12.23.
//

import DesignLibrary
import SwiftUI

struct SendMessageMentionChannelView: View {
    @State var viewModel: SendMessageMentionChannelViewModel

    @Bindable var sendMessageViewModel: SendMessageViewModel

    var body: some View {
        DataStateView(data: $viewModel.channels) {
            if let candidate = sendMessageViewModel.searchChannel().map(String.init) {
                await viewModel.search(idOrName: candidate)
            }
        } content: { channels in
            if channels.isEmpty {
                if let candidate = sendMessageViewModel.searchChannel().map(String.init) {
                    ContentUnavailableView.search(text: candidate)
                } else {
                    ContentUnavailableView(R.string.localizable.channelsUnavailable(), systemImage: "magnifyingglass")
                }
            } else {
                ScrollView {
                    ForEach(channels) { channel in
                        HStack {
                            Button {
                                sendMessageViewModel.replace(channel: channel)
                            } label: {
                                Label(channel.name, systemImage: "number")
                            }
                            .foregroundStyle(.secondary)
                            Spacer()
                        }
                        Divider()
                    }
                }
                .contentMargins([.horizontal, .top], .l, for: .scrollContent)
            }
            if !sendMessageViewModel.isEditing {
                Divider()
            }
        }
        .onChange(of: sendMessageViewModel.text, initial: true) {
            search()
        }
    }
}

@MainActor
private extension SendMessageMentionChannelView {
    func search() {
        if let candidate = sendMessageViewModel.searchChannel().map(String.init) {
            Task {
                await viewModel.search(idOrName: candidate)
            }
        }
    }
}
