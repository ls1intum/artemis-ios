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

/// Matches the last 'number' symbol followed by a candidate.
/// The candidate is a possible channel name.
enum SendMessageChannelCandidate {

    private static let regex = #/#(?<candidate>[\w-]*)/#

    static func search(text: String) -> Substring? {
        let matches = text.matches(of: regex)
        return matches.last?.candidate
    }

    static func replace(text: inout String, channel: ChannelIdAndNameDTO) {
        guard let candidate = search(text: text) else {
            return
        }

        // Replaces all occurrences. Otherwise, we need to get the match.
        let range = Range<String.Index>?.none

        text = text.replacingOccurrences(
            of: "#" + candidate,
            with: "[channel]\(channel.name)(\(channel.id))[/channel]",
            range: range)
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
