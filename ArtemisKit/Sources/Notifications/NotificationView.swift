//
//  SwiftUIView.swift
//  
//
//  Created by Sven Andabaka on 17.03.23.
//

import SwiftUI
import DesignLibrary
import Navigation
import PushNotifications

struct NotificationView: View {

    @ObservedObject var viewModel: NotificationViewModel

    @Environment(\.dismiss) var dismiss

    @State private var showTargetNotFoundAlert = false

    var body: some View {
        NavigationView {
            List {
                DataStateView(data: $viewModel.notifications,
                              retryHandler: { await viewModel.loadNotifications() }) { notifications in
                    if notifications.isEmpty {
                        Text(R.string.localizable.no_notifications_yet_label())
                    } else {
                        ForEach(notifications) { notification in
                            NotificationCell(notification: notification)
                                .onTapGesture {
                                    dismiss()
                                    guard let type = notification.pushNotificationType,
                                          let targetPath = PushNotificationResponseHandler.getTarget(type: type, targetString: notification.target) else {
                                        showTargetNotFoundAlert = true
                                        return
                                    }
                                    DeeplinkHandler.shared.handle(path: targetPath)
                                }
                        }
                    }
                }.listRowSeparator(.hidden)
            }
                .listStyle(PlainListStyle())
                .refreshable {
                    await viewModel.loadNotifications()
                }
                .navigationTitle(R.string.localizable.notifications_title())
                .onAppear {
                    Task {
                        await viewModel.updateNotificationSeenDate()
                    }
                }
                .alert(R.string.localizable.notification_target_not_found(), isPresented: $showTargetNotFoundAlert) {
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
                    Text(R.string.localizable.notification_author_label(notification.notificationDate.shortDateAndTime,
                                                                        notification.author?.name ?? R.string.localizable.artemis_label()))
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

    @State private var showNotificationSheet = false

    func body(content: Content) -> some View {
        content
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: { showNotificationSheet = true }, label: {
                        Image(systemName: "bell.fill")
                            .overlay(Badge(count: viewModel.newNotificationCount))
                    })
                }
            }
            .sheet(isPresented: $showNotificationSheet) {
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

private struct NewExerciseTarget: Codable {
    var id: Int
    var course: Int
}
