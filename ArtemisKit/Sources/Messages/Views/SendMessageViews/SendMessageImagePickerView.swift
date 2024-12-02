//
//  SendMessageImagePickerView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 09.11.24.
//

import PhotosUI
import SwiftUI

struct SendMessageImagePickerView: View {

    var sendViewModel: SendMessageViewModel
    @State private var viewModel: SendMessageUploadImageViewModel

    init(sendMessageViewModel: SendMessageViewModel) {
        self._viewModel = State(initialValue: .init(courseId: sendMessageViewModel.course.id,
                                                    conversationId: sendMessageViewModel.conversation.id))
        self.sendViewModel = sendMessageViewModel
    }

    var body: some View {
        PhotosPicker(selection: $viewModel.selection,
                     matching: .images,
                     preferredItemEncoding: .compatible) {
            Label(R.string.localizable.uploadImage(), systemImage: "photo.fill")
        }
        .onChange(of: viewModel.selection) {
            viewModel.onChange()
        }
        .sheet(isPresented: viewModel.showUploadScreen) {
            if let path = viewModel.imagePath {
                sendViewModel.insertImageMention(path: path)
            }
            viewModel.selection = nil
            viewModel.image = nil
        } content: {
            UploadImageView(viewModel: viewModel)
        }
    }
}

private struct UploadImageView: View {
    var viewModel: SendMessageUploadImageViewModel
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
        if let image = viewModel.image {
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
