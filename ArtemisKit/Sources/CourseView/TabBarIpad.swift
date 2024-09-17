//
//  TabBarIpad.swift
//
//
//  Created by Anian Schleyer on 08.09.24.
//

import Navigation
import SwiftUI

/// Tab Bar Background for iPadOS 18
/// Since the Tab Bar is at the top, we can use this space for our back button
struct TabBarIpad<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @Environment(\.horizontalSizeClass) var sizeClass

    var body: some View {
        if sizeClass == .compact {
            // Old Tab Bar is shown
            content()
        } else {
            // Floating Tab Bar is shown
            VStack(spacing: 0) {
                HStack(alignment: .center) {
                    BackToRootButton(placement: .tabBar, sizeClass: sizeClass)
                    Spacer()
                }
                .padding(.horizontal)
                .frame(height: 50)
                .frame(maxWidth: .infinity)
                .background(.thinMaterial)

                content()
            }
        }
    }
}
