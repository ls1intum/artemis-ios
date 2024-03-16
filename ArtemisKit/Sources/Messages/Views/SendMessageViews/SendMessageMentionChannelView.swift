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
        HStack {
            Spacer()
            DataStateView(data: $viewModel.channels) {
                if let candidate = sendMessageViewModel.searchChannel().map(String.init) {
                    await viewModel.search(idOrName: candidate)
                }
            } content: { channels in
                if !channels.isEmpty {
                    List {
                        ForEach(channels) { channel in
                            Button(channel.name) {
                                sendMessageViewModel.replace(channel: channel)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(R.string.localizable.channelsUnavailable(), systemImage: "magnifyingglass")
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
private extension SendMessageMentionChannelView {
    func search() {
        if let candidate = sendMessageViewModel.searchChannel().map(String.init) {
            Task {
                await viewModel.search(idOrName: candidate)
            }
        }
    }
}
