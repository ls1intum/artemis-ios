//
//  TabBarIpad.swift
//
//
//  Created by Anian Schleyer on 08.09.24.
//

import Navigation
import Notifications
import SwiftUI

/// Tab Bar Background for iPadOS 18
/// Since the Tab Bar is at the top, we can use this space for our back button
struct TabBarIpad<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        if sizeClass == .compact || UIDevice.current.userInterfaceIdiom != .pad {
            // Old Tab Bar is shown
            content()
        } else {
            // Floating Tab Bar is shown
            layout {
                HStack(alignment: .center) {
                    BackToRootButton(placement: .tabBar, sizeClass: sizeClass)
                    Spacer()
                    NotificationToolbarButton(placement: .tabBar, sizeClass: sizeClass)
                }
                .imageScale(.large)
                .padding(.horizontal)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(.thinMaterial)
                .zIndex(1)

                content()
            }
        }
    }

    private var layout: AnyLayout {
        if #available(iOS 18.4, *) {
            // Change in iOS 18.4:
            // SplitView inside TabView has space built in for TabBar at the top
            AnyLayout(ZStackLayout(alignment: .top))
        } else {
            AnyLayout(VStackLayout(spacing: 0))
        }
    }
}
