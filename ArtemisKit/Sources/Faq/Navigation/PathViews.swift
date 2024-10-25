//
//  PathViews.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 24.10.24.
//

import DesignLibrary
import SwiftUI

public struct FaqPathView: View {
    @State private var viewModel: FaqPathViewModel

    public init(path: FaqPath) {
        self._viewModel = State(initialValue: FaqPathViewModel(path: path))
    }

    public var body: some View {
        DataStateView(data: $viewModel.faq) {
            await viewModel.loadFaq()
        } content: { faq in
            FaqDetailView(faq: faq, namespace: viewModel.path.namespace)
        }
        .task {
            if case .loading = viewModel.faq {
                await viewModel.loadFaq()
            }
        }
    }
}
