import SwiftUI
import UniformTypeIdentifiers

struct SendMessageFilePickerView: View {
    var sendViewModel: SendMessageViewModel
    @State private var viewModel: SendMessageUploadFileViewModel

    init(sendMessageViewModel: SendMessageViewModel) {
        self._viewModel = State(initialValue: .init(
            courseId: sendMessageViewModel.course.id,
            conversationId: sendMessageViewModel.conversation.id
        ))
        self.sendViewModel = sendMessageViewModel
    }

    var body: some View {
        Button {
            viewModel.isFilePickerPresented = true
        } label: {
            Label("Upload File", systemImage: "doc.fill")
        }
        .sheet(isPresented: $viewModel.isFilePickerPresented) {
            FilePickerView(viewModel: viewModel)
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

/// SwiftUI wrapper for `UIDocumentPickerViewController`
private struct FilePickerView: UIViewControllerRepresentable {
    let viewModel: SendMessageUploadFileViewModel

    func makeUIViewController(context: Context) -> UIDocumentPickerViewController {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: viewModel.allowedFileTypes, asCopy: true)
        documentPicker.allowsMultipleSelection = false
        documentPicker.delegate = context.coordinator
        return documentPicker
    }

    func updateUIViewController(_ uiViewController: UIDocumentPickerViewController, context: Context) {
    }

    func makeCoordinator() -> Coordinator {
        Coordinator(viewModel: viewModel)
    }

    class Coordinator: NSObject, UIDocumentPickerDelegate {
        private let viewModel: SendMessageUploadFileViewModel

        init(viewModel: SendMessageUploadFileViewModel) {
            self.viewModel = viewModel
        }

        func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
            if let url = urls.first {
                viewModel.filePicked(at: url)
            } else {
                viewModel.uploadState = .failed(error: .init(title: "Failed to pick file"))
            }
        }
    }
}
