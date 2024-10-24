//
//  SelectDetailView.swift
//
//
//  Created by Anian Schleyer on 04.09.24.
//

import SwiftUI

public struct SelectDetailView: View {
    @EnvironmentObject var navController: NavigationController

    @State private var animation = true

    public init() {}

    public var body: some View {
        VStack {
            ZStack {
                Image(systemName: "arrow.backward")
                    .offset(x: animation ? 0 : -6)
            }
            .animation(.spring(.bouncy(extraBounce: 0.4)), value: animation)
            .padding(10)
            .font(.title2)
            .background {
                Circle()
                    .strokeBorder(style: .init())
            }
            .foregroundStyle(.secondary)

            Text(selectionText)
        }
        .onChange(of: animation, initial: true) { _, newValue in
            let newTime = newValue ? 3 : 0.25
            DispatchQueue.main.asyncAfter(deadline: .now() + newTime) {
                animation.toggle()
            }
        }
    }

    var selectionText: String {
        return switch navController.courseTab {
        case .exercise:
            R.string.localizable.selectExercise()
        case .lecture:
            R.string.localizable.selectLecture()
        case .communication:
            R.string.localizable.selectConversation()
        case .faq:
            "Select faq" // TODO
        }
    }
}
