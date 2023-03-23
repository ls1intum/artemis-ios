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
    var borderColor: Color
    var cornerRadius: CGFloat

    func body(content: Content) -> some View {
        content
            .background(backgroundColor)
            .cornerRadius(cornerRadius)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(borderColor, lineWidth: hasBorder ? 1 : 0)
            )
    }
}

public extension View {
    func cardModifier(backgroundColor: Color = Color.Artemis.cardBackgroundColor,
                      hasBorder: Bool = false,
                      borderColor: Color = Color.Artemis.cardBorderColor,
                      cornerRadius: CGFloat = 16) -> some View {
        modifier(CardModifier(backgroundColor: backgroundColor,
                              hasBorder: hasBorder,
                              borderColor: borderColor,
                              cornerRadius: cornerRadius))
    }
}
