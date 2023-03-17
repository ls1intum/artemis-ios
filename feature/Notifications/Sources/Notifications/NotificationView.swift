//
//  SwiftUIView.swift
//  
//
//  Created by Sven Andabaka on 17.03.23.
//

import SwiftUI
import DesignLibrary

public struct NotificationView: View {

    @StateObject private var viewModel = NotificationViewModel()

    public init() { }

    public var body: some View {
        NavigationView {
            List {
                DataStateView(data: $viewModel.notifications,
                              retryHandler: { await viewModel.loadNotifications() }) { notifications in
                    if notifications.isEmpty {
                        Text("No Notifications yet!")
                    } else {
                        ForEach(notifications) { notification in
                            NotificationCell(notification: notification)
                        }
                    }
                }.listRowSeparator(.hidden)
            }
                .listStyle(PlainListStyle())
                .refreshable {
                    await viewModel.loadNotifications()
                }
                .task {
                    await viewModel.loadNotifications()
                }
                .navigationTitle("TODO")
        }
    }
}

struct NotificationCell: View {

    let notification: Notification

    var body: some View {
        VStack {
            Text(notification.title)
                .font(.title2)
            if let text = notification.text {
                Text(text)
            }
        }
    }
}
