//
//  File.swift
//
//
//  Created by Sven Andabaka on 04.03.23.
//

import SwiftUI

struct CardModifier: ViewModifier {

    var backgroundColor: Color
    var hasBorder: Bool

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(16)
            .overlay(
                RoundedRectangle(cornerRadius: 16)
                    .stroke(Color.Artemis.cardBorderColor, lineWidth: hasBorder ? 1 : 0)
            )
    }
}

public extension View {
    func cardModifier(backgroundColor: Color = Color.Artemis.cardBackgroundColor,
                      hasBorder: Bool = false) -> some View {
        modifier(CardModifier(backgroundColor: backgroundColor,
                              hasBorder: hasBorder))
    }
}
