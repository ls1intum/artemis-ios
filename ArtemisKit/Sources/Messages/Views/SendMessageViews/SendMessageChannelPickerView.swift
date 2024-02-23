//
//  SendMessageChannelPickerView.swift
//
//
//  Created by Nityananda Zbil on 02.12.23.
//

import Common
import DesignLibrary
import SharedModels
import SwiftUI

struct SendMessageChannelPickerView: View {

    @State var viewModel: SendMessageChannelPickerViewModel

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
            .onChange(of: sendMessageViewModel.text, initial: true, search)
            Spacer()
        }
    }
}

private extension SendMessageChannelPickerView {
    func search() {
        if let candidate = sendMessageViewModel.searchChannel().map(String.init) {
            Task {
                await viewModel.search(idOrName: candidate)
            }
        }
    }
}
