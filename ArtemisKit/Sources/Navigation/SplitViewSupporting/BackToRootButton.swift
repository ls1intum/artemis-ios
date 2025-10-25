//
//  BackToRootButton.swift
//
//
//  Created by Anian Schleyer on 04.09.24.
//

import SwiftUI

public struct BackToRootButton: View {
    public enum Placement {
        case navBar, tabBar
    }

    @EnvironmentObject var navController: NavigationController

    private let placement: Placement
    private let sizeClass: UserInterfaceSizeClass?

    public init(placement: Placement, sizeClass: UserInterfaceSizeClass?) {
        self.placement = placement
        self.sizeClass = sizeClass
    }

    public var body: some View {
        // Only show this button in the NavBar if we are on compact width,
        // Otherwise we have a separate bar with a back button
        if placement != .navBar || sizeClass == .compact || !iPad {
            Button {
                navController.popToRoot()
            } label: {
                backButtonLabel
            }
        }
    }

    @ViewBuilder private var backButtonLabel: some View {
        if #available(iOS 26.0, *) {
            Image(systemName: "chevron.backward")
                .frame(width: 45, height: 45)
                .toolbarStyle26(enabled: placement == .navBar)
        } else {
            HStack(spacing: .s) {
                Image(systemName: "chevron.backward")
                    .fontWeight(.semibold)
                Text("Back")
            }
            .offset(x: placement == .navBar ? -8 : 0)
        }
    }

    private var iPad: Bool {
        UIDevice.current.userInterfaceIdiom == .pad
    }
}

@available(iOS 26.0, *)
fileprivate extension View {
    @ViewBuilder
    func toolbarStyle26(enabled: Bool) -> some View {
        if enabled {
            glassEffect(.regular.interactive(), in: .circle)
                .offset(x: -8)
        } else {
            self
        }
    }
}
