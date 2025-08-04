//
//  SendMessageImagePickerView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 09.11.24.
//

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
        Button(R.string.localizable.uploadImage(), systemImage: "photo.fill") {
            viewModel.isImagePickerPresented = true
        }
        .imagePicker(isPresented: $viewModel.isImagePickerPresented, selectedImage: $viewModel.selection)
        .onChange(of: viewModel.selection) {
            viewModel.onChange()
        }
        .sheet(isPresented: viewModel.showUploadScreen) {
            if let path = viewModel.filePath {
                sendViewModel.insertImageMention(path: path, image: viewModel.image)
            }
            viewModel.selection = nil
            viewModel.image = nil
        } content: {
            UploadFileProgressView(viewModel: viewModel)
        }
    }
}
