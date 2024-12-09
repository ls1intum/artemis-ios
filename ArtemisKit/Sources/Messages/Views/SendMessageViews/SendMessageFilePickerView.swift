import SwiftUI
import UniformTypeIdentifiers

struct SendMessageFilePickerView: View {
    var sendViewModel: SendMessageViewModel
    @State private var viewModel: SendMessageUploadFileViewModel
    @State private var showFileImporter = false
    @State private var showUploadSheet = false

    init(sendMessageViewModel: SendMessageViewModel) {
        self._viewModel = State(initialValue: .init(
            courseId: sendMessageViewModel.course.id,
            conversationId: sendMessageViewModel.conversation.id
        ))
        self.sendViewModel = sendMessageViewModel
    }

    var body: some View {
        VStack {
            Button {
                showFileImporter = true
            } label: {
                Label("Upload File", systemImage: "doc.fill")
            }
        }
        .fileImporter(
            isPresented: $showFileImporter,
            allowedContentTypes: viewModel.allowedFileTypes,
            allowsMultipleSelection: false
        ) { result in
            switch result {
            case .success(let urls):
                if let url = urls.first {
                    viewModel.onChange(fileUrl: url)
                    showUploadSheet = true
                }
            case .failure(let error):
                print("File selection error: \(error)")
            }
        }
        .sheet(isPresented: $showUploadSheet, onDismiss: {
            if let path = viewModel.filePath, viewModel.uploadState == .done {
                sendViewModel.insertFileMention(path: path, fileName: viewModel.fileName ?? "file")
            }
            viewModel.resetFileSelection()
        }) {
            UploadFileView(viewModel: viewModel)
        }
    }
}

private struct UploadFileView: View {
    var viewModel: SendMessageUploadFileViewModel
    @Environment(\.dismiss) var dismiss

    var body: some View {
        ZStack {
            VStack {
                statusIcon

                Text(viewModel.statusLabel)
                    .frame(maxWidth: 300)
                    .font(.title)

                if viewModel.uploadState == .uploading {
                    Button("Cancel") {
                        viewModel.cancel()
                    }
                    .buttonStyle(.bordered)
                }
            }
            .animation(.easeInOut, value: viewModel.uploadState)
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
        .transition(.opacity)
    }
}
