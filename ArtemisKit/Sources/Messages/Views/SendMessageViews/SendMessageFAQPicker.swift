//
//  SendMessageFAQPicker.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 07.12.24.
//

import SharedModels
import SwiftUI

struct SendMessageFAQPicker: View {

    @State var viewModel: SendMessageFAQPickerViewModel

    var body: some View {
        Group {
            if !viewModel.faqs.isEmpty {
                List(viewModel.faqs) { faq in
                    Button {
                        viewModel.select(faq: faq)
                    } label: {
                        Text(faq.questionTitle)
                            .lineLimit(2)
                    }
                }
                .listStyle(.plain)
            } else {
                ContentUnavailableView(R.string.localizable.lecturesUnavailable(), systemImage: "magnifyingglass")
            }
        }
        .task {
            await viewModel.loadFAQs()
        }
        .navigationTitle(R.string.localizable.faqs())
        .navigationBarTitleDisplayMode(.inline)
    }
}

extension SendMessageFAQPicker {
    init(course: Course, delegate: SendMessageMentionContentDelegate) {
        self.init(viewModel: SendMessageFAQPickerViewModel(course: course, delegate: delegate))
    }
}
