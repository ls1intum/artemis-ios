//
//  Chip.swift
//  
//
//  Created by Sven Andabaka on 20.03.23.
//

import SwiftUI

public struct Chip: View {

    var text: String
    var backgroundColor: Color

    public init(text: String, backgroundColor: Color) {
        self.text = text
        self.backgroundColor = backgroundColor
    }

    public var body: some View {
        Text(text)
            .bold()
            .lineLimit(1)
            .foregroundColor(.white)
            .padding(.m)
            .background(backgroundColor)
            .cornerRadius(8)
    }
}
