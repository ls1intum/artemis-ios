//
//  MessagesTabView.swift
//  
//
//  Created by Sven Andabaka on 03.04.23.
//

import SwiftUI
import DesignLibrary

public struct MessagesTabView: View {

    @StateObject private var viewModel: MessagesTabViewModel

    public init(courseId: Int) {
        self._viewModel = StateObject(wrappedValue: MessagesTabViewModel(courseId: courseId))
    }

    public var body: some View {
        List {
            DisclosureGroup("Channels") {
                DataStateView(data: $viewModel.channels,
                              retryHandler: { await viewModel.loadConversations() }) { channels in
                    ForEach(channels, id: \.id) { channel in
                        Text(channel.conversationName)
                    }
                }
            }
        }
            .task {
                await viewModel.loadConversations()
            }
    }
}
