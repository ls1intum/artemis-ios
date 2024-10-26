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
        .navigationBarTitleDisplayMode(.large)
        .modifier(TransitionIfAvailable(id: faq.id, namespace: namespace))
    }
}

private struct TransitionIfAvailable: ViewModifier {
    let id: Int64
    let namespace: Namespace.ID?

    func body(content: Content) -> some View {
        if let namespace {
            content
                .navigationTransition(.zoom(sourceID: id, in: namespace))
        } else {
            content
        }
    }
}
