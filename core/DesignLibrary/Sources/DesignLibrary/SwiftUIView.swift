//
//  SwiftUIView.swift
//  
//
//  Created by Sven Andabaka on 04.03.23.
//

import SwiftUI

public struct ArtemisTextField: TextFieldStyle {

    var backgroundColor: Color = Color.Artemis.textFieldColor

    public init() { }

    public func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.m)
            .background(backgroundColor)
            .cornerRadius(4)
    }
}
