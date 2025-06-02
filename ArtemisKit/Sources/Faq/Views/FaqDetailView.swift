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
            VStack(alignment: .leading, spacing: .m) {
                Text(faq.questionTitle)
                    .font(.title2.bold())
                ArtemisMarkdownView(string: faq.questionAnswer)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .contentMargins(.l)
        .navigationTitle(faq.questionTitle)
        .navigationBarTitleDisplayMode(.inline)
        .modifier(TransitionIfAvailable(id: faq.id ?? 0, namespace: namespace))
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
