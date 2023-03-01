//
//  LoadingIndicator.swift
//  Artemis Exam Check
//
//  Created by Sven Andabaka on 27.01.23.
//

import SwiftUI

struct LoadingIndicator: ViewModifier {
    @Binding var isLoading: Bool

    func body(content: Content) -> some View {
        ZStack {
            content
                .disabled(isLoading)
                .blur(radius: isLoading ? 3 : 0)
            if isLoading {
                ProgressView()
            }
        }
    }
}

public extension View {
    func loadingIndicator(isLoading: Binding<Bool>) -> some View {
        modifier(LoadingIndicator(isLoading: isLoading))
    }
}
