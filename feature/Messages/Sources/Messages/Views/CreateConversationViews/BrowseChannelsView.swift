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

    @State private var searchText = ""

    var filteredResults: [Channel] {
        (viewModel.allChannels.value ?? []).filter {
            $0.conversationName.lowercased().contains(searchText.lowercased()) || ($0.description?.lowercased().contains(searchText.lowercased()) ?? false)
        }
    }

    @Environment(\.dismiss) var dismiss

    init(courseId: Int) {
        _viewModel = StateObject(wrappedValue: BrowseChannelsViewModel(courseId: courseId))
    }

    var body: some View {
        NavigationView {
            List {
                DataStateView(data: $viewModel.allChannels,
                              retryHandler: { await viewModel.getAllChannels() }) { allChannels in
                    if searchText.isEmpty {
                        ForEach(allChannels, id: \.id) { channel in
                            ChannelRow(viewModel: viewModel, channel: channel, dismissAction: dismiss)
                        }
                    } else {
                        ForEach(filteredResults, id: \.id) { channel in
                            ChannelRow(viewModel: viewModel, channel: channel, dismissAction: dismiss)
                        }
                    }
                }
            }
            .searchable(text: $searchText)
            .task {
                await viewModel.getAllChannels()
            }
            .navigationTitle(R.string.localizable.browseChannelsNavTitel())
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(R.string.localizable.cancel()) {
                        dismiss()
                    }
                }
            }
        }
    }
}

private struct ChannelRow: View {

    @EnvironmentObject var navigationController: NavigationController

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
                        Chip(text: R.string.localizable.joinedLabel(), backgroundColor: .Artemis.badgeSuccessColor)
                    }
                    Text(R.string.localizable.numberOfMembers(channel.numberOfMembers ?? 0))
                }
                if let description = channel.description {
                    Text(description)
                        .font(.caption)
                }
            }
            Spacer()
            if !(channel.isMember ?? false) {
                Button(R.string.localizable.joinButtonLabel()) {
                    viewModel.isLoading = true
                    Task(priority: .userInitiated) {
                        let success = await viewModel.joinChannel(channelId: channel.id)
                        viewModel.isLoading = false
                        if success {
                            dismissAction()
                        }
                    }
                }
                    .buttonStyle(ArtemisButton())
                    .loadingIndicator(isLoading: $viewModel.isLoading)
            }
        }
            .alert(isPresented: $viewModel.showError, error: viewModel.error, actions: {})
    }
}
