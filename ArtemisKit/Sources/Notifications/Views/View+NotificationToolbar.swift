//
//  View+NotificationToolbar.swift
//
//
//  Created by Nityananda Zbil on 11.12.23.
//

import SwiftUI

public extension View {
    func notificationToolbar() -> some View {
        modifier(NotificationBell())
    }
}

private struct NotificationBell: ViewModifier {

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

private struct Badge: View {
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
