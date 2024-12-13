import SwiftUI
import UniformTypeIdentifiers

struct SendMessageFilePickerView: View {
    var sendViewModel: SendMessageViewModel
    @State private var viewModel: SendMessageUploadFileViewModel
    @State private var isFilePickerPresented = false
    @State private var delegateHandler: DelegateHandler?

    init(sendMessageViewModel: SendMessageViewModel) {
        self._viewModel = State(initialValue: .init(
            courseId: sendMessageViewModel.course.id,
            conversationId: sendMessageViewModel.conversation.id
        ))
        self.sendViewModel = sendMessageViewModel
    }

    var body: some View {
        Button(action: {
            openFilePicker()
        }) {
            Label("Upload File", systemImage: "doc.fill")
        }
        .sheet(isPresented: viewModel.showUploadScreen) {
            if let path = viewModel.filePath {
                sendViewModel.insertImageMention(path: path)
            }
            viewModel.cancel()
        } content: {
            UploadFileProgressView(viewModel: viewModel)
        }
    }

    private func openFilePicker() {
        let documentPicker = UIDocumentPickerViewController(forOpeningContentTypes: viewModel.allowedFileTypes, asCopy: true)
        documentPicker.allowsMultipleSelection = false
        
        let handler = DelegateHandler(
            onFileSelected: { url in
                viewModel.onChange(from: url, displayPath: {
                    if let filePath = viewModel.filePath {
                        sendViewModel.insertFileMention(path: filePath, fileName: viewModel.fileName ?? "filename")
                    }
                    viewModel.resetFileSelection()
                })
            },
            onCancel: {
                print("File selection canceled")
            }
        )
        delegateHandler = handler // Retain the handler

        documentPicker.delegate = handler

        if let rootVC = UIApplication.shared.windows.first?.rootViewController {
            rootVC.present(documentPicker, animated: true)
        }
    }
}

class DelegateHandler: NSObject, UIDocumentPickerDelegate {
    private let onFileSelected: (URL) -> Void
    private let onCancel: () -> Void

    init(onFileSelected: @escaping (URL) -> Void, onCancel: @escaping () -> Void) {
        self.onFileSelected = onFileSelected
        self.onCancel = onCancel
    }

    func documentPicker(_ controller: UIDocumentPickerViewController, didPickDocumentsAt urls: [URL]) {
        if let url = urls.first {
            onFileSelected(url)
        }
    }

    func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
        onCancel()
    }
}
