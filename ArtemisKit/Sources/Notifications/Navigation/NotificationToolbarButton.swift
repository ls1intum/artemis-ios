//
//  NotificationToolbarButton.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 23.03.25.
//

import Navigation
import ProfileInfo
import SwiftUI

public struct NotificationToolbarButton: View {
    public enum Placement {
        case navBar, tabBar
    }

    private let placement: Placement
    private let sizeClass: UserInterfaceSizeClass?

    @State private var showNotificationSheet = false
    @FeatureAvailability(.courseNotifications)
    var featureEnabled

    @EnvironmentObject private var navController: NavigationController
    private var courseId: Int {
        navController.selectedCourse?.id ?? 0
    }

    public init(placement: Placement, sizeClass: UserInterfaceSizeClass?) {
        self.placement = placement
        self.sizeClass = sizeClass
    }

    public var body: some View {
        // Only show this button in the NavBar if we are on compact width,
        // Otherwise we have a separate bar (iPad)
        if featureEnabled && (placement != .navBar || sizeClass == .compact || !iPad) {
            Button(R.string.localizable.notificationsTitle(), systemImage: "bell.fill") {
                showNotificationSheet = true
            }
            .labelStyle(.iconOnly)
            .popover(isPresented: $showNotificationSheet, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
                NotificationView(courseId: courseId)
                    .frame(minWidth: 400, minHeight: 600)
            }
        }
    }

    private var iPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}
