//
//  SwiftUIView.swift
//  
//
//  Created by Sven Andabaka on 17.03.23.
//

import SwiftUI
import DesignLibrary

struct NotificationView: View {

    @ObservedObject var viewModel: NotificationViewModel

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

    @StateObject private var viewModel = NotificationViewModel()

    @State private var showNotificationSheet = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showNotificationSheet = true }, label: {
                        //                    Label(R.string.localizable.dashboard_notifications_label(), systemImage: "bell.fill")
                        Label("TODO", systemImage: "bell.fill")
                            .overlay(Badge(count: viewModel.newNotificationCount))
                    })
                }
            }
            .sheet(isPresented: $showNotificationSheet) {
                NotificationView(viewModel: viewModel)
            }
    }
}

public extension View {
    func notificationToolBar() -> some View {
        modifier(NotificationBell())
    }
}

struct Badge: View {
    let count: Int

    var body: some View {
        // swiftlint:disable:next empty_count
        if count > 0 {
            ZStack(alignment: .topTrailing) {
                Color.clear
                Text(String(count))
                    .font(.system(size: 16))
                    .foregroundColor(.white)
                    .padding(.s)
                    .background(Color.red)
                    .clipShape(Circle())
                    .alignmentGuide(.top) { $0[.bottom] }
                    .alignmentGuide(.trailing) { $0[.trailing] - $0.width * 0.25 }
            }
        } else {
            EmptyView()
        }
    }
}
