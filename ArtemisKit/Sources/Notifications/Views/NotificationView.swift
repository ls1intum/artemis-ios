//
//  SwiftUIView.swift
//  
//
//  Created by Sven Andabaka on 17.03.23.
//

import DesignLibrary
import Navigation
import PushNotifications
import SwiftUI

struct NotificationView: View {

    @ObservedObject var viewModel: NotificationViewModel

    @Environment(\.dismiss) var dismiss

    @State private var isTargetNotFoundAlertPresented = false

    var body: some View {
        NavigationStack {
            DataStateView(data: $viewModel.notifications) {
                await viewModel.loadNotifications()
            } content: { notifications in
                if notifications.isEmpty {
                    ContentUnavailableView(R.string.localizable.noNotifications(), systemImage: "bell")
                } else {
                    List {
                        ForEach(notifications) { notification in
                            NotificationListRowView(notification: notification)
                                .onTapGesture {
                                    dismiss()
                                    guard let type = notification.pushNotificationType,
                                          let targetPath = PushNotificationResponseHandler.getTarget(type: type, targetString: notification.target) else {
                                        isTargetNotFoundAlertPresented = true
                                        return
                                    }
                                    DeeplinkHandler.shared.handle(path: targetPath)
                                }
                        }
                        .listRowSeparator(.hidden)
                    }
                }
            }
            .listStyle(.plain)
            .refreshable {
                await viewModel.loadNotifications()
            }
            .navigationTitle(R.string.localizable.notificationsTitle())
            .navigationBarTitleDisplayMode(.inline)
            .onAppear {
                Task {
                    await viewModel.updateNotificationSeenDate()
                }
            }
            .alert(R.string.localizable.notificationTargetNotFound(), isPresented: $isTargetNotFoundAlertPresented) {
                Button(R.string.localizable.ok(), role: .cancel) { }
            }
        }
    }
}

private struct NotificationListRowView: View {

    let notification: Notification

    var body: some View {
        if let title = notification.encodedTitle,
           let body = notification.encodedBody {
            VStack(alignment: .leading, spacing: .m) {
                Text(title)
                    .font(.title2)
                Text(body)
                HStack {
                    Spacer()
                    Text(R.string.localizable.notificationAuthorLabel(
                        notification.notificationDate.shortDateAndTime,
                        notification.author?.name ?? R.string.localizable.artemisLabel()))
                    .multilineTextAlignment(.trailing)
                    .foregroundColor(Color.Artemis.secondaryLabel)
                }
            }
            .padding(.l)
            .cardModifier(backgroundColor: Color.Artemis.modalCardBackgroundColor)
        }
    }
}
