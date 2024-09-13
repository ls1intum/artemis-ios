//
//  FixBlankScreenView.swift
//
//
//  Created by Anian Schleyer on 08.09.24.
//

import SwiftUI

/// **Workaround for a SwiftUI Bug.**
/// SwiftUI renders a blank screen in some cases when opening the
/// Course TabView on Exercises or Lectures. Introducing a small
/// delay before showing the view fixes the issue for some reason.
struct FixBlankScreenView<Content: View>: View {
    @ViewBuilder var content: () -> Content
    @State private var displayContent = false

    var body: some View {
        Group {
            if displayContent {
                content()
            } else {
                Spacer()
                    .task {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.01) {
                            displayContent = true
                        }
                    }
            }
        }
    }
}
