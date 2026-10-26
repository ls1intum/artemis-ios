//
//  TabBarIpad.swift
//
//
//  Created by Anian Schleyer on 08.09.24.
//

import Navigation
import Notifications
import Quiz
import SwiftUI

/// Tab Bar Background for iPadOS 18
/// Since the Tab Bar is at the top, we can use this space for our back button
struct TabBarIpad<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @Environment(\.horizontalSizeClass) var sizeClass
    @State private var trainingSessionVisible = false

    var body: some View {
        Group {
            if sizeClass == .compact || UIDevice.current.userInterfaceIdiom != .pad {
                // Old Tab Bar is shown
                content()
            } else {
                // Floating Tab Bar is shown
                ZStack(alignment: .top) {
                    if !trainingSessionVisible {
                        HStack(alignment: .center) {
                            BackToRootButton(placement: .tabBar, sizeClass: sizeClass)
                                .frame(width: 45, height: 45)
                                .glassEffect(.regular.interactive(), in: .circle)
                            Spacer()
                            NotificationToolbarButton(placement: .tabBar, sizeClass: sizeClass)
                                .frame(width: 45, height: 45)
                                .glassEffect(.regular.interactive(), in: .circle)
                        }
                        .imageScale(.large)
                        .padding(.horizontal)
                        .frame(height: 50)
                        .frame(maxWidth: .infinity)
                        .zIndex(1)
                    }

                    content()
                }
            }
        }
        .onPreferenceChange(QuizTrainingSessionVisibilityKey.self) { trainingSessionVisible = $0 }
    }
}
