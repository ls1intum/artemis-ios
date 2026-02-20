//
//  DisableSwipeDownToDismiss.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 19.02.26.
//

// Adapted from - https://stackoverflow.com/a/79772679

import SwiftUI
import UIKit

extension View {
    /// Disables the swipe down gesture for zoom navigation transitions.
    /// Swiping from the leading edge remains enabled.
    func disableSwipeDownToDismiss() -> some View {
        modifier(DisableSwipeDownToDismissModifier())
    }
}

private struct DisableSwipeDownToDismissModifier: ViewModifier {
    func body(content: Self.Content) -> some View {
        content
            .background {
                ZoomTransitionAdapter()
                    .frame(width: 0, height: 0)
            }
    }
}

private struct ZoomTransitionAdapter: UIViewControllerRepresentable {
    func makeUIViewController(context: Self.Context) -> ZoomTransitionAdapterController {
        ZoomTransitionAdapterController()
    }

    func updateUIViewController(_ uiViewController: ZoomTransitionAdapterController,
                                context: Self.Context) {}
}

private final class ZoomTransitionAdapterController: UIViewController {
    private var zoomTransitionOptions: UIViewController.Transition.ZoomOptions? {
        parent?.preferredTransition?.value(forKey: "options") as? UIViewController.Transition.ZoomOptions
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        zoomTransitionOptions?.interactiveDismissShouldBegin = { context in
            // Only allow swipes from the leading edge
            context.location.x < 30
        }
    }
}
