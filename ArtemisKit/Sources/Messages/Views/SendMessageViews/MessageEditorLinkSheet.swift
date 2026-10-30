import SwiftUI

struct MessageEditorLinkSheet: View {
    let editor: MessageEditorDocument
    @Environment(\.dismiss) private var dismiss
    @State private var label = ""
    @State private var address = "https://"

    private var isValid: Bool { editor.canSetLink && MessageEditorLinkValidation.isValid(address) }

    var body: some View {
        NavigationStack {
            Form {
                TextField(R.string.localizable.linkLabel(), text: $label)
                TextField(R.string.localizable.linkAddress(), text: $address)
                    .textContentType(.URL)
                    .keyboardType(.URL)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                if editor.linkRange != nil {
                    Button(R.string.localizable.removeLink(), role: .destructive) {
                        editor.unlink()
                        dismiss()
                    }
                }
            }
            .navigationTitle(R.string.localizable.link())
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button(R.string.localizable.cancel()) { dismiss() }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button(R.string.localizable.saveLink()) {
                        editor.setLink(label: label, address: address)
                        dismiss()
                    }
                    .disabled(!isValid)
                }
            }
            .onAppear {
                if let details = editor.linkDetails {
                    label = details.label
                    address = details.address
                } else if let range = Range(editor.selection, in: editor.content.string) {
                    label = String(editor.content.string[range])
                }
            }
        }
    }
}
