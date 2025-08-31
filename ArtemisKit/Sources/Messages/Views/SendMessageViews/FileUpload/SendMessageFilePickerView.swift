import SwiftUI
import UniformTypeIdentifiers

struct SendMessageFilePickerView: View {
    var sendViewModel: SendMessageViewModel
    @State private var viewModel: SendMessageUploadFileViewModel

    init(sendMessageViewModel: SendMessageViewModel) {
        self._viewModel = State(initialValue: .init(courseId: sendMessageViewModel.course.id,
                                                    conversationId: sendMessageViewModel.conversation.id))
        self.sendViewModel = sendMessageViewModel
    }

    var body: some View {
        Button {
            viewModel.isFilePickerPresented = true
        } label: {
            Label("Upload File", systemImage: "doc.fill")
        }
        .filePicker(isPresented: $viewModel.isFilePickerPresented,
                    onFilePicked: viewModel.filePicked(at:)) { error in
            viewModel.uploadState = .failed(error: .init(title: error.localizedDescription))
        }
        .sheet(isPresented: viewModel.showUploadScreen) {
            if let path = viewModel.filePath {
                sendViewModel.insertFileMention(path: path, fileName: viewModel.fileName ?? "file")
            }
            viewModel.resetFileSelection()
        } content: {
            UploadFileProgressView(viewModel: viewModel)
        }
    }
}
