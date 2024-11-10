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
            // TODO: Localize
            Label("Upload Image", systemImage: "photo.fill")
        }
                     .onChange(of: viewModel.selection) {
                         viewModel.onChange()
                     }
                     .sheet(isPresented: viewModel.showUploadScreen) {
                         if let path = viewModel.imagePath {
                             sendViewModel.insertImageMention(path: path)
                         }
                     } content: {
                         Text("Uploading: \(viewModel.uploadState)")
                     }
    }
}
