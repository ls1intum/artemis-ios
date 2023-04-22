//
//  BrowseChannelsView.swift
//  
//
//  Created by Sven Andabaka on 21.04.23.
//

import SwiftUI
import SharedModels
import DesignLibrary
import Navigation

struct BrowseChannelsView: View {

    @StateObject private var viewModel: BrowseChannelsViewModel

    @Environment(\.dismiss) var dismiss

    init(courseId: Int) {
        _viewModel = StateObject(wrappedValue: BrowseChannelsViewModel(courseId: courseId))
    }

    var body: some View {
        NavigationView {
            List {
                DataStateView(data: $viewModel.allChannels,
                              retryHandler: { await viewModel.getAllChannels() }) { allChannels in
                    ForEach(allChannels, id: \.id) { channel in
                        ChannelRow(viewModel: viewModel, channel: channel, dismissAction: dismiss)
                    }
                }
            }
            .task {
                await viewModel.getAllChannels()
            }
            .navigationTitle("Browse Channels")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct ChannelRow: View {

    @ObservedObject var viewModel: BrowseChannelsViewModel

    let channel: Channel
    let dismissAction: DismissAction

    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                HStack {
                    if let icon = channel.icon {
                        icon
                            .resizable()
                            .scaledToFit()
                            .frame(width: .extraSmallImage, height: .extraSmallImage)
                    }
                    Text(channel.conversationName)
                }.bold()
                HStack {
                    if channel.isMember ?? false {
                        Chip(text: "Joined", backgroundColor: .Artemis.badgeSuccessColor)
                    }
                    Text("\(channel.numberOfMembers ?? 0) Members")
                }
                if let description = channel.description {
                    Text(description)
                        .font(.caption)
                }
            }
            Spacer()
            if !(channel.isMember ?? false) {
                Button("Join") {
                    Task(priority: .userInitiated) {
                        let success = await viewModel.joinChannel(channelId: channel.id)
                        if success {
                            dismissAction()
                        }
                    }
                }.buttonStyle(ArtemisButton())
            }
        }
            .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
    }
}
