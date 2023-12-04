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

    /// `regex` matches a prefix and the last number symbol followed by a candidate. The candidate is a possible channel
    /// name.
    private static let regex = #/(?<prefix>[^#]*)#(?<candidate>.*)/#

    static func search(text: String) -> Substring? {
        text.wholeMatch(of: regex)?.candidate
    }

    static func replace(text: inout String, channel: ChannelIdAndNameDTO) {
        text.replace(regex) { match in
            match.prefix + "[channel]\(channel.name)(\(channel.id))[/channel]"
        }
    }
}

struct SendMessageChannelPicker: View {

    @StateObject private var viewModel: SendMessageChannelPickerModel

    @Binding var text: String

    init(course: Course, conversation: Conversation, text: Binding<String>) {
        self._viewModel = StateObject(wrappedValue: SendMessageChannelPickerModel(course: course, conversation: conversation))
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
                await viewModel.search(idOrName: candidate)
            }
        }
    }
}
