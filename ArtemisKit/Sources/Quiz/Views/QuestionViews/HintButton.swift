//
//  HintButton.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 09.10.26.
//

import SwiftUI

struct HintButton: View {
    let hint: String

    @State private var showHint = false

    var body: some View {
        Button {
            showHint = true
        } label: {
            Label(R.string.localizable.hint(), systemImage: "questionmark.circle.fill")
        }
        .labelStyle(.iconOnly)
        .popover(isPresented: $showHint, attachmentAnchor: .point(.bottom), arrowEdge: .top) {
            ScrollView(.vertical) {
                VStack {
                    Text(R.string.localizable.hint())
                        .font(.title2)

                    Text(hint)
                        .font(.body)
                }
                .padding()
                .tint(.primary)
            }
            .frame(maxWidth: 280, minHeight: 200)
            .presentationCompactAdaptation(.none)
        }
    }
}
