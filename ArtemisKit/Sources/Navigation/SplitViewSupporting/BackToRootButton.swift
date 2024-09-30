//
//  BackToRootButton.swift
//
//
//  Created by Anian Schleyer on 04.09.24.
//

import SwiftUI

public struct BackToRootButton: View {
    @EnvironmentObject var navController: NavigationController

    public init() {}

    public var body: some View {
        Button {
            navController.popToRoot()
        } label: {
            HStack(spacing: .s) {
                Image(systemName: "chevron.backward")
                    .fontWeight(.semibold)
                Text("Back")
            }
            .offset(x: -8)
        }
    }
}
