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
        if !mentionedImages.isEmpty {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(viewModel.mentionedImages, id: \.image.hashValue) { name, _, image in
                        ImageAttachmentThumbnail(image: image, name: name)
                    }
                }
            }
            .contentMargins(.horizontal, .l, for: .scrollContent)
        }
    }
}

private struct ImageAttachmentThumbnail: View {
    @State private var showPreview = false
    let image: UIImage
    let name: String

    var body: some View {
        Button {
            showPreview = true
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
                    Button(R.string.localizable.done()) {
                        showPreview = false
                    }
                }
        }
        .frame(minWidth: 250, minHeight: 250)
    }
}
