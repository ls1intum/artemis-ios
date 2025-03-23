//
//  CourseNotificationView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 23.03.25.
//

import DesignLibrary
import PushNotifications
import SwiftUI

struct CourseNotificationView: View {
    @State private var viewModel: CourseNotificationViewModel
    @Environment(\.dismiss) private var dismiss

    init(courseId: Int) {
        _viewModel = State(initialValue: CourseNotificationViewModel(courseId: courseId))
    }

    var body: some View {
        NavigationStack {
            DataStateView(data: $viewModel.notifications) {
                await viewModel.loadNotifications()
            } content: { _ in
                List {
                    Section {
                        FilterBarPicker(selectedFilter: $viewModel.filter, hiddenFilters: [])
                    }

                    ForEach(viewModel.filteredNotifications) { notification in
                        SingleNotificationView(notification: notification)
                    }

                    if viewModel.filteredNotifications.isEmpty {
                        ContentUnavailableView(R.string.localizable.noNotifications(), systemImage: viewModel.filter.iconName)
                    }
                }
                .animation(.default, value: viewModel.filter)
                .listRowSpacing(.m)
            }
            .navigationTitle(R.string.localizable.notificationsTitle())
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(R.string.localizable.close(), systemImage: "xmark.circle.fill") {
                        dismiss()
                    }
                    .buttonStyle(.plain)
                    .foregroundStyle(.gray)
                    .font(.title2)
                }
            }
        }
        .task {
            await viewModel.loadNotifications()
        }
    }
}

private struct SingleNotificationView: View {
    let notification: CourseNotification

    var body: some View {
        if let notification = notification.notification.displayable {
            HStack(spacing: .l) {
                CourseNotificationIconView(notification: self.notification)
                    .frame(maxWidth: 50)

                VStack(alignment: .leading) {
                    Text(notification.title)
                        .font(.title2)
                        .fontWeight(.semibold)

                    if let subtitle = notification.subtitle {
                        Text(subtitle)
                            .font(.headline)
                    }

                    if let body = notification.body {
                        Text(body)
                            .lineLimit(notification.bodyLineLimit)
                    }
                }
            }
        }
    }
}
