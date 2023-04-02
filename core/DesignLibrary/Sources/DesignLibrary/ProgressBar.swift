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
    let backgroundColor: Color
    let ringColor: Color

    public init(value: Int,
                total: Int,
                backgroundColor: Color = Color.Artemis.courseScoreProgressBackgroundColor,
                ringColor: Color = Color.Artemis.courseScoreProgressRingColor) {
        self.value = value
        self.total = total
        self.backgroundColor = backgroundColor
        self.ringColor = ringColor
    }

    private var progress: Double {
        Double(value) / Double(total)
    }

    public var body: some View {
        ZStack {
            Circle()
                .stroke(lineWidth: 20.0)
                .foregroundColor(backgroundColor)

            Circle()
                .trim(from: 0.0, to: CGFloat(min(self.progress, 1.0)))
                .stroke(style: StrokeStyle(lineWidth: 20.0, lineCap: .round, lineJoin: .round))
                .foregroundColor(ringColor)
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
