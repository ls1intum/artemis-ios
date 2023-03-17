//
//  SwiftUIView.swift
//  
//
//  Created by Sven Andabaka on 17.03.23.
//

import SwiftUI
import DesignLibrary

struct NotificationView: View {

    @StateObject private var viewModel = NotificationViewModel()

    @Binding var badgeCount: Int

    var body: some View {
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
                .navigationTitle("TODO")
                .onChange(of: viewModel.newNotificationCount) {
                    badgeCount = $0
                }
                .onAppear {
                    viewModel.lastNotificationSeenDate = .now
                }
        }
    }
}

struct NotificationCell: View {

    let notification: Notification

    var body: some View {
        VStack(alignment: .leading, spacing: .m) {
            Text(notification.title)
                .font(.title2)
            if let text = notification.text {
                Text(text)
            }
            HStack {
                Spacer()
                Text("\(notification.notificationDate.shortDateAndTime) by \(notification.author?.name ?? "Artemis")")
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(Color.Artemis.secondaryLabel)
            }
        }
            .padding(.l)
            .cardModifier(backgroundColor: Color.Artemis.modalCardBackgroundColor)
    }
}

struct NotificationBell: ViewModifier {

    @State private var badgeCount = 0
    @State private var showNotificationSheet = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showNotificationSheet = true }, label: {
                        //                    Label(R.string.localizable.dashboard_notifications_label(), systemImage: "bell.fill")
                        Label("TODO", systemImage: "bell.fill")
                    }).badge(badgeCount)
                }
            }
            .sheet(isPresented: $showNotificationSheet) {
                NotificationView(badgeCount: $badgeCount)
            }
    }
}

public extension View {
    func notificationToolBar() -> some View {
        modifier(NotificationBell())
    }
}
