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
        DataStateView(data: $viewModel.attachmentUrl) {
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
            viewModel.attachmentUrl = .loading
            await viewModel.loadAttachmentUrl()
        }
    }
}
