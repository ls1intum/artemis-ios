//
//  ProgressBar.swift
//  
//
//  Created by Sven Andabaka on 15.03.23.
//

import SwiftUI

public struct ProgressBar: View {

    let value: Int
    let total: Int
    let color: Color

    public init(value: Int, total: Int, color: Color) {
        self.value = value
        self.total = total
        self.color = color
    }

    private var progress: Double {
        Double(value) / Double(total)
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 20.0)
                .opacity(0.3)
                .foregroundColor(color)

            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 20.0, lineCap: .round, lineJoin: .round))
                .foregroundColor(color)
                .rotationEffect(Angle(degrees: 270.0))
                .animation(.linear, value: progress)
            VStack {
                Text("\(value) / \(total)")
                    .font(.title3)
                Text("Pts")
            }
        }
    }
}
