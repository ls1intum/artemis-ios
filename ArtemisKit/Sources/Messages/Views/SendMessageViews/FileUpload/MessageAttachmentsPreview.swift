import SwiftUI

struct MessageAttachmentsPreview: View {
    let viewModel: SendMessageViewModel
    @State private var renamingAttachment: MessageEditorAttachment?
    @State private var attachmentName = ""

    var body: some View {
        if !viewModel.editor.attachments.isEmpty {
            ScrollView(.horizontal) {
                HStack {
                    ForEach(viewModel.editor.attachments) { attachment in
                        MessageAttachmentThumbnail(viewModel: viewModel, attachment: attachment) {
                            attachmentName = attachment.name
                            renamingAttachment = attachment
                        }
                    }
                }
            }
            .contentMargins(.horizontal, .l, for: .scrollContent)
            .alert(R.string.localizable.renameAttachment(), isPresented: Binding(
                get: { renamingAttachment != nil },
                set: { if !$0 { renamingAttachment = nil } }
            )) {
                TextField(R.string.localizable.attachmentName(), text: $attachmentName)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                Button(R.string.localizable.cancel(), role: .cancel) { renamingAttachment = nil }
                if let attachment = renamingAttachment {
                    Button(R.string.localizable.renameAttachment()) {
                        viewModel.editor.renameAttachment(attachment, to: attachmentName)
                        renamingAttachment = nil
                    }
                    .disabled(attachmentName.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                }
            }
        }
    }
}

private struct MessageAttachmentThumbnail: View {
    @State private var showPreview = false
    let viewModel: SendMessageViewModel
    let attachment: MessageEditorAttachment
    let rename: () -> Void

    private var image: UIImage? { viewModel.uploadedImages[attachment.path] }

    var body: some View {
        Menu {
            if attachment.isImage, image != nil {
                Button(R.string.localizable.previewAttachment(), systemImage: "eye") { showPreview = true }
            }
            Button(R.string.localizable.renameAttachment(), systemImage: "pencil", action: rename)
            Button(R.string.localizable.removeAttachment(), systemImage: "minus.circle", role: .destructive) {
                viewModel.editor.removeAttachment(attachment)
            }
        } label: {
            VStack(spacing: .s) {
                Group {
                    if attachment.isImage, let image {
                        Image(uiImage: image)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Image(systemName: attachment.isImage ? "photo" : "doc")
                            .font(.title)
                            .frame(maxWidth: .infinity, maxHeight: .infinity)
                            .background(.quaternary)
                    }
                }
                .frame(width: .largeImage, height: .largeImage)
                .clipShape(.rect(cornerRadius: .m))
                Text(attachment.name)
                    .font(.caption)
                    .lineLimit(1)
                    .frame(maxWidth: .largeImage)
            }
        }
        .buttonStyle(.plain)
        .accessibilityLabel(attachment.name)
        .accessibilityIdentifier("message-attachment-\(attachment.id)")
        .popover(isPresented: $showPreview, attachmentAnchor: .point(.top), arrowEdge: .bottom) {
            NavigationStack {
                if let image {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFit()
                        .navigationTitle(attachment.name)
                        .toolbar {
                            ToolbarItem(placement: .confirmationAction) {
                                Button(R.string.localizable.done()) { showPreview = false }
                            }
                        }
                }
            }
            .frame(minWidth: 250, minHeight: 250)
        }
    }
}
