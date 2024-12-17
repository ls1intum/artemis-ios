//
//  SwipeToReply.swift
//
//
//  Created by Anian Schleyer on 10.08.24.
//

import SwiftUI

struct SwipeToReply: ViewModifier {
    @State private var state = SwipeToReplyState()

    let enabled: Bool
    let onSwipe: () -> Void

    func body(content: Content) -> some View {
        content
            .gesture(swipeToReplyGesture)
            .blur(radius: state.messageBlur)
            .overlay(alignment: .trailing) {
                swipeToReplyOverlay
            }
            .onDisappear(perform: state.reset)
    }

    @ViewBuilder var swipeToReplyOverlay: some View {
        Image(systemName: "arrowshape.turn.up.left.circle.fill")
            .resizable()
            .scaledToFit()
            .frame(width: 40)
            .foregroundStyle(state.swiped ? .blue : .gray)
            .padding(.horizontal)
            .offset(x: state.overlayOffset)
            .scaleEffect(x: state.overlayScale, y: state.overlayScale, anchor: .trailing)
            .opacity(state.overlayOpacity)
            .animation(.easeInOut(duration: 0.1), value: state.swiped)
            .accessibilityHidden(true)
    }

    var swipeToReplyGesture: some Gesture {
        DragGesture(minimumDistance: 25)
            .onChanged { value in
                // No swiping in Thread View
                guard enabled else { return }

                // Only allow swipe to the left
                let distance = min(value.translation.width, 0)

                self.state.update(with: distance)
            }
            .onEnded { _ in
                if self.state.swiped {
                    onSwipe()
                } else {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        self.state.reset()
                    }
                }
            }
    }
}
