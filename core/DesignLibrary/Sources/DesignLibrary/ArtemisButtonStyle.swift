//
//  SwiftUIView.swift
//
//
//  Created by Sven Andabaka on 04.03.23.
//

import SwiftUI

public enum ButtonPriority {
    case primary, secondary, custom
}

public struct ArtemisButton: ButtonStyle {

    @Environment(\.isEnabled) var isEnabled

    var width: CGFloat = UIScreen.main.bounds.size.width
    var verticalInlinePadding: CGFloat = .m
    var horizontalInlinePadding: CGFloat = .l
    var buttonColor = Color.Artemis.primaryButtonColor
    var buttonTextColor = Color.Artemis.primaryButtonTextColor
    var buttonPriority: ButtonPriority = .primary

    public init(priority: ButtonPriority = .primary) {
        self.buttonPriority = priority
    }

    // TODO: maybe add custom priority init

    public func makeBody(configuration: ButtonStyleConfiguration) -> some View {
        configuration.label
            .lineLimit(1)
            .font(.headline)
            .minimumScaleFactor(0.5)
            .padding(.vertical, verticalInlinePadding)
            .padding(.horizontal, horizontalInlinePadding)
            .background(buttonBackgroundColorWrapper.opacity(isEnabled ? 1 : 0.5))
            .foregroundColor(buttonTextColorWrapper)
            .clipShape(RoundedRectangle(cornerRadius: 4))
            .overlay(RoundedRectangle(cornerRadius: 4).stroke(buttonTextColorWrapper).opacity(buttonPriority == .secondary ? 1 : 0))
            .scaleEffect(configuration.isPressed ? 1.1 : 1)
            .animation(.easeOut(duration: 0.2), value: configuration.isPressed)
    }

    var buttonBackgroundColorWrapper: Color {
        switch buttonPriority {
        case .primary:
            return Color.Artemis.primaryButtonColor
        case .secondary:
            return .clear
        case .custom:
            return buttonColor
        }
    }

    var buttonTextColorWrapper: Color {
        switch buttonPriority {
        case .primary:
            return Color.Artemis.primaryButtonTextColor
        case .secondary:
            return Color.Artemis.secondaryButtonTextColor
        case .custom:
            return buttonTextColor
        }
    }
}
