//
//  SwiftUIView.swift
//  
//
//  Created by Sven Andabaka on 17.03.23.
//

import SwiftUI
import DesignLibrary
import Navigation

struct NotificationView: View {

    @ObservedObject var viewModel: NotificationViewModel

    @Environment(\.dismiss) var dismiss

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
                                    let decoder = JSONDecoder()
                                    guard let target = try? decoder.decode(NewExerciseTarget.self, from: Data(notification.target.utf8)) else { return }
                                    let targetPath = "courses/\(target.course)/exercises/\(target.id)"
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
                Text(R.string.localizable.notification_author_label(notification.notificationDate.shortDateAndTime,
                                                                    notification.author?.name ?? R.string.localizable.artemis_label()))
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
