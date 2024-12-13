//
//  UploadFileView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 13.12.24.
//

import SwiftUI

struct UploadFileProgressView: View {
    var viewModel: UploadViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            backgroundImage

            VStack {
                statusIcon

                Text(viewModel.statusLabel)
                    .frame(maxWidth: 300)
                    .font(.title)

                if viewModel.uploadState == .uploading {
                    Button(R.string.localizable.cancel()) {
                        viewModel.cancel()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .animation(.smooth(duration: 0.2), value: viewModel.uploadState)
        }
        .interactiveDismissDisabled()
    }

    @ViewBuilder var statusIcon: some View {
        Group {
            if viewModel.uploadState != .done && viewModel.error == nil {
                ProgressView()
                    .progressViewStyle(.circular)
                    .scaleEffect(1.5)
            }
            if viewModel.uploadState == .done {
                Image(systemName: "checkmark.circle.fill")
                    .foregroundStyle(.green)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
                            dismiss()
                        }
                    }
            }
            if viewModel.error != nil {
                Image(systemName: "xmark.circle.fill")
                    .foregroundStyle(.red)
                    .onAppear {
                        DispatchQueue.main.asyncAfter(deadline: .now() + 3) {
                            dismiss()
                        }
                    }
            }
        }
        .font(.largeTitle)
        .frame(height: 60)
        .transition(.blurReplace)
    }

    @ViewBuilder var backgroundImage: some View {
        if let vm = viewModel as? SendMessageUploadImageViewModel,
           let image = vm.image {
            Image(uiImage: image)
                .resizable()
                .scaledToFill()
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .ignoresSafeArea()
                .blur(radius: 10, opaque: true)
                .opacity(0.2)
        }
    }
}

