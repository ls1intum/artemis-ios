//
//  CourseNotificationView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 23.03.25.
//

import DesignLibrary
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
                        Text(String(describing: notification.notification))
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
