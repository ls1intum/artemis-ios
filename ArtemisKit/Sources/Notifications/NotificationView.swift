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
        NavigationView {
            DataStateView(data: $viewModel.notifications) {
                await viewModel.loadNotifications()
            } content: { notifications in
                if notifications.isEmpty {
                    ContentUnavailableView(R.string.localizable.noNotifications(), systemImage: "bell")
                } else {
                    List {
                        ForEach(notifications) { notification in
                            NotificationCell(notification: notification)
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

struct NotificationCell: View {

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
        } else {
            EmptyView()
        }
    }
}

struct NotificationBell: ViewModifier {

    @StateObject private var viewModel = NotificationViewModel()

    @State private var isNotificationSheetPresented = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button {
                        isNotificationSheetPresented = true
                    } label: {
                        Image(systemName: "bell.fill")
                            .overlay(Badge(count: viewModel.newNotificationCount))
                    }
                }
            }
            .sheet(isPresented: $isNotificationSheetPresented) {
                NotificationView(viewModel: viewModel)
            }
            .task {
                await viewModel.subscribeToNotificationUpdates()
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
