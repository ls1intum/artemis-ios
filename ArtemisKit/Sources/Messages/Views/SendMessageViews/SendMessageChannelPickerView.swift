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

enum SendMessageChannelCandidate {

    /// `regex` matches the last number symbol followed by a candidate. The candidate is a possible channel name.
    private static let regex = #/#(?<candidate>.*)/#

    static func search(text: String) -> Substring? {
        #warning("Shorten")
        let matches = text.matches(of: #/#(?<candidate>.*)/#)
        matches.forEach { m in
            log.info(m.candidate)
        }
        guard let match = matches.last, text.hasSuffix(match.0) else {
            return nil
        }
        return match.candidate
    }

    static func replace(text: inout String, channel: ChannelIdAndNameDTO) {
        guard let search = search(text: text) else {
            return
        }
        #warning("#")
        text.replace("#" + search, with: "[channel]\(channel.name)(\(channel.id))[/channel]")
    }
}

struct SendMessageChannelPickerView: View {

    @State private var viewModel: SendMessageChannelPickerViewModel

    @Binding var text: String

    init(course: Course, conversation: Conversation, text: Binding<String>) {
        self.viewModel = SendMessageChannelPickerViewModel(course: course, conversation: conversation)
        self._text = text
    }

    var body: some View {
        HStack {
            Spacer()
            DataStateView(data: $viewModel.channels) {
                if let candidate = SendMessageChannelCandidate.search(text: text).map(String.init) {
                    await viewModel.search(idOrName: candidate)
                }
            } content: { channels in
                if !channels.isEmpty {
                    List {
                        ForEach(channels) { channel in
                            Button(channel.name) {
                                SendMessageChannelCandidate.replace(text: &text, channel: channel)
                            }
                        }
                    }
                } else {
                    ContentUnavailableView(R.string.localizable.channelsUnavailable(), systemImage: "magnifyingglass")
                }
            }
            .onAppear(perform: search)
            .onChange(of: text, search)
            Spacer()
        }
    }
}

private extension SendMessageChannelPickerView {
    func search() {
        if let candidate = SendMessageChannelCandidate.search(text: text).map(String.init) {
            Task {
                await viewModel.search(idOrName: candidate)
            }
        }
    }
}
