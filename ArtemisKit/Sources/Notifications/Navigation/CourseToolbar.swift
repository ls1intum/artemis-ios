//
//  CourseToolbar.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 26.03.25.
//

import Navigation
import SwiftUI

public extension View {
    /// Use this modifier at a high level (e.g. CourseView) with title to provide a toolbar.
    /// Use at lower level (e.g. ExerciseList) to attach toolbar where needed.
    @ViewBuilder
    func courseToolbar(title: String? = nil, overrideWithDismiss: Bool = false) -> some View {
        if !overrideWithDismiss {
            modifier(CourseToolbarViewEnvironmentModifier(title: title))
        } else {
            modifier(DismissModifier())
        }
    }
}

private struct CourseToolbarViewEnvironmentModifier: ViewModifier {
    @Environment(\.courseToolbar) var toolbarModifier
    @Environment(\.horizontalSizeClass) var sizeClass
    let title: String?

    func body(content: Content) -> some View {
        if let title {
            content.environment(\.courseToolbar, CourseToolbarViewModifier(sizeClass: sizeClass, title: title))
        } else {
            content.modifier(toolbarModifier)
        }
    }
}

private struct CourseToolbarViewModifier: ViewModifier {
    let sizeClass: UserInterfaceSizeClass?
    let title: String

    func body(content: Content) -> some View {
        content
            .navigationTitle(title)
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    BackToRootButton(placement: .navBar, sizeClass: sizeClass)
                }
                .disableGlass26()
                ToolbarItem(placement: .topBarTrailing) {
                    NotificationToolbarButton(placement: .navBar, sizeClass: sizeClass)
                }
            }
    }
}

private struct DismissModifier: ViewModifier {
    @Environment(\.dismiss) private var dismiss

    func body(content: Content) -> some View {
        content
            .toolbarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button(R.string.localizable.close()) {
                        dismiss()
                    }
                }
            }
    }
}

fileprivate extension ToolbarContent {
    func disableGlass26() -> some ToolbarContent {
        Group {
            if #available(iOS 26, *) {
                sharedBackgroundVisibility(.hidden)
            } else {
                self
            }
        }
    }
}

// MARK: Environment+CourseToolbar

private enum CourseToolbarEnvironmentKey: EnvironmentKey {
    static let defaultValue = CourseToolbarViewModifier(sizeClass: .compact, title: "No title set")
}

private extension EnvironmentValues {
    var courseToolbar: CourseToolbarViewModifier {
        get {
            self[CourseToolbarEnvironmentKey.self]
        }
        set {
            self[CourseToolbarEnvironmentKey.self] = newValue
        }
    }
}
