//
//  File.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 24.12.24.
//

import Common
import DesignLibrary
import SwiftUI

struct MessageAttachmentSheet: View {
    @Environment(\.dismiss) var dismiss
    @State var viewModel: MessageAttachmentViewModel

    init(url: URL) {
        self._viewModel = State(initialValue: .init(url: url))
    }

    var body: some View {
        DataStateView(data: Binding<DataState<URL>>(get: {
            guard let url = viewModel.attachmentUrl else {
                return .loading
            }
            switch url {
            case .success(let value):
                return .done(response: value)
            case .failure(let error):
                return .failure(error: error)
            }
        }, set: { newValue in
            switch newValue {
            case .done(let response):
                viewModel.attachmentUrl = .success(response)
            case .failure(let error):
                viewModel.attachmentUrl = .failure(error)
            case .loading:
                viewModel.attachmentUrl = nil
            }
        })) {
            await viewModel.loadAttachmentUrl()
        } content: { fileUrl in
            NavigationStack {
                QuickLookController(url: fileUrl)
                    .navigationTitle(R.string.localizable.attachment())
                    .navigationBarTitleDisplayMode(.inline)
                    .toolbar {
                        ToolbarItem(placement: .confirmationAction) {
                            Button(R.string.localizable.done()) {
                                dismiss()
                            }
                        }
                    }
                    .background(Color(uiColor: .secondarySystemBackground))
            }
        }
        .task {
            viewModel.attachmentUrl = nil
            await viewModel.loadAttachmentUrl()
        }
    }
}
