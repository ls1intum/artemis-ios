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
                        VStack(spacing: .s) {
                            Image(uiImage: image)
                                .resizable()
                                .scaledToFill()
                                .frame(width: .largeImage, height: .largeImage)
                                .clipShape(.rect(cornerRadius: .m))

                            Text(name)
                                .font(.caption)
                                .frame(maxWidth: .largeImage)
                        }
                    }
                }
            }
            .contentMargins(.horizontal, .l, for: .scrollContent)
        }
    }
}
