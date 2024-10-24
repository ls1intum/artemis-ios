//
//  FaqDetailView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 24.10.24.
//

import ArtemisMarkdown
import SharedModels
import SwiftUI

struct FaqDetailView: View {
    let faq: FaqDTO
    let namespace: Namespace.ID?

    var body: some View {
        ScrollView {
            ArtemisMarkdownView(string: faq.questionAnswer)
                .frame(maxWidth: .infinity, alignment: .leading)
                .padding(.horizontal, .l)
        }
        .navigationTitle(faq.questionTitle)
        .navigationTransition(.zoom(sourceID: faq.id, in: namespace ?? Namespace().wrappedValue))
    }
}
