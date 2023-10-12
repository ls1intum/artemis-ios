//
//  File.swift
//  
//
//  Created by Nityananda Zbil on 12.10.23.
//

import SwiftUI

struct AppStorePreview: ViewModifier {
    let title: String

    func body(content: Content) -> some View {
        ZStack {
            content
            LinearGradient(
                colors: [
                    Color.clear,
                    Color.clear,
                    Color.clear,
                    Color(
                        red: 48/256, green: 112/256, blue: 179/256),
                ],
                startPoint: .top,
                endPoint: .bottom)
            .ignoresSafeArea()
            VStack {
                Spacer()
                HStack {
                    Spacer()
                    Text(title)
                        .font(.title)
                        .multilineTextAlignment(.center)
                        .padding()
                    Spacer()
                }
                .background {
                    RoundedRectangle(
                        cornerRadius: 25.0,
                        style: .continuous)
                    .foregroundStyle(Color.white)
                }
                .padding()
            }
            .ignoresSafeArea()
        }
    }
}
