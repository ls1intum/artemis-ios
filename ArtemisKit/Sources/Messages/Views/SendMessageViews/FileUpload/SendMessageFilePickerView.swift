import SwiftUI
import UniformTypeIdentifiers

struct SendMessageFilePickerView: View {
    @Bindable private var viewModel: SendMessageUploadFileViewModel

    init(viewModel: SendMessageUploadFileViewModel) {
        self.viewModel = viewModel
    }

    var body: some View {
        Button {
            viewModel.isFilePickerPresented = true
        } label: {
            Label(R.string.localizable.uploadFile(), systemImage: "doc.fill")
        }
    }
}
