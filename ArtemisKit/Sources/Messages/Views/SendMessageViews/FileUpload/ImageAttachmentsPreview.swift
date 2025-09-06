//
//  ImageAttachmentsPreview.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 03.08.25.
//

import SwiftUI

struct ImageAttachmentsPreview: View {
    let viewModel: SendMessageViewModel

    var body: some View {
        let mentionedImages = viewModel.mentionedImages
        if !mentionedImages.isEmpty && !viewModel.previewVisible {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(viewModel.mentionedImages, id: \.image.hashValue) { name, path, image in
                        ImageAttachmentThumbnail(viewModel: viewModel, image: image, name: name, path: path)
                    }
                }
            }
            .contentMargins(.horizontal, .l, for: .scrollContent)
        }
    }
}

private struct ImageAttachmentThumbnail: View {
    @State private var showPreview = false
    let viewModel: SendMessageViewModel
    let image: UIImage
    let name: String
    let path: String

    var body: some View {
        Menu {
            Button(R.string.localizable.removeImage(), systemImage: "minus.circle", role: .destructive) {
                viewModel.removeImage(name: name, path: path)
            }
        } label: {
            VStack(spacing: .s) {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFill()
                    .frame(width: .largeImage, height: .largeImage)
                    .clipShape(.rect(cornerRadius: .m))

                Text(name)
                    .font(.caption)
                    .lineLimit(1)
                    .frame(maxWidth: .largeImage)
            }
        } primaryAction: {
            showPreview = true
        }
        .buttonStyle(.plain)
        .popover(isPresented: $showPreview, attachmentAnchor: .point(.top), arrowEdge: .bottom) {
            preview
        }
    }

    private var preview: some View {
        NavigationStack {
            Image(uiImage: image)
                .resizable()
                .scaledToFit()
                .toolbar {
                    ToolbarItem(placement: .confirmationAction) {
                        Button(R.string.localizable.done()) {
                            showPreview = false
                        }
                    }
                    ToolbarItem(placement: .bottomBar) {
                        Button(R.string.localizable.removeImage(), systemImage: "minus.circle", role: .destructive) {
                            showPreview = false
                            viewModel.removeImage(name: name, path: path)
                        }
                    }
                }
        }
        .frame(minWidth: 250, minHeight: 250)
    }
}
