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
        if placement != .navBar || sizeClass == .compact {
            Button {
                navController.popToRoot()
            } label: {
                HStack(spacing: .s) {
                    Image(systemName: "chevron.backward")
                        .fontWeight(.semibold)
                    Text("Back")
                }
                .offset(x: placement == .navBar ? -8 : 0)
            }
        }
    }
}
