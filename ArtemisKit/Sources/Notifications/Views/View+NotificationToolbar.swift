//
//  View+NotificationToolbar.swift
//
//
//  Created by Nityananda Zbil on 11.12.23.
//

import ProfileInfo
import SwiftUI

public extension View {
    func notificationToolbar() -> some View {
        modifier(NotificationBellContainer())
    }
}

// Wrapper to conditionally apply Notification modifier
private struct NotificationBellContainer: ViewModifier {
    @FeatureAvailability(.courseNotifications)
    var disabled

    func body(content: Content) -> some View {
        if !disabled {
            content.modifier(NotificationBell())
        } else {
            content
        }
    }
}

private struct NotificationBell: ViewModifier {

    @StateObject private var viewModel = NotificationViewModel()

    @State private var isNotificationSheetPresented = false
    @Environment(\.horizontalSizeClass) var horizontalSize

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
                    .popover(isPresented: $isNotificationSheetPresented) {
                        let minSize: CGFloat? =
                        if UIDevice.current.userInterfaceIdiom == .pad && horizontalSize != .compact {
                            // If not shown as a sheet, we need to set a size.
                            // Otherwise, it will be too small for its content.
                            min(UIScreen.main.bounds.width, UIScreen.main.bounds.height) * 0.8
                        } else {
                            // If shown as a sheet, the default size works for us
                            nil
                        }
                        NotificationView(viewModel: viewModel)
                            .frame(minWidth: minSize, minHeight: minSize)
                    }
                }
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
