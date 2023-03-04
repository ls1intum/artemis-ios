//
//  File.swift
//  
//
//  Created by Sven Andabaka on 04.03.23.
//

import SwiftUI


struct CardModifier: ViewModifier {
    func body(content: Content) -> some View {
        content
            .background(Color.Artemis.cardBackgroundColor)
            .cornerRadius(16)
    }
}

public extension View {
    func cardModifier() -> some View {
        modifier(CardModifier())
    }
}
