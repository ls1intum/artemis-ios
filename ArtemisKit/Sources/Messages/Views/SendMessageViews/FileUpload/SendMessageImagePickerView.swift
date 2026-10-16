//
//  SendMessageImagePickerView.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 09.11.24.
//

import SwiftUI

struct SendMessageImagePickerView: View {

    @Bindable private var viewModel: SendMessageUploadImageViewModel

    init(viewModel: SendMessageUploadImageViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Button(R.string.localizable.uploadImage(), systemImage: "photo.fill") {
            viewModel.isImagePickerPresented = true
        }
    }
}
