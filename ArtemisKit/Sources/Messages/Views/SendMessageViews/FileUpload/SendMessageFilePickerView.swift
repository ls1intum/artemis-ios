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
            Label("Upload File", systemImage: "doc.fill")
        }
    }
}
