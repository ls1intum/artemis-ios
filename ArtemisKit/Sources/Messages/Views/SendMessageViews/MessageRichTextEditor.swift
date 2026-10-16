import SwiftUI
import UIKit

/// UIKit keeps native selection, IME composition and undo while the document stores wire Markdown.
struct MessageRichTextEditor: UIViewRepresentable {
    var document: MessageEditorDocument
    var placeholder: String
    @Binding var isFocused: Bool
    var expanded: Bool

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> MessageComposerTextView {
        let view = MessageComposerTextView()
        view.delegate = context.coordinator
        view.document = document
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 8
        view.textContainerInset = UIEdgeInsets(top: 8, left: 4, bottom: 8, right: 4)
        view.adjustsFontForContentSizeCategory = true
        view.allowsEditingTextAttributes = false
        view.accessibilityIdentifier = "message-rich-text-editor"
        view.accessibilityLabel = placeholder
        view.font = .preferredFont(forTextStyle: .body)
        context.coordinator.textView = view
        document.applyEdit = { [weak coordinator = context.coordinator] value, range in coordinator?.apply(value, selection: range) }
        return view
    }

    func updateUIView(_ view: MessageComposerTextView, context: Context) {
        context.coordinator.parent = self
        guard view.markedTextRange == nil else { return }
        context.coordinator.applying = true
        defer { context.coordinator.applying = false }
        if !view.attributedText.isEqual(to: document.content) {
            view.attributedText = document.content
            view.invalidateIntrinsicContentSize()
        }
        if view.selectedRange != document.selection { view.selectedRange = document.selection }
        view.typingAttributes = MessageEditorDocument.attributes(document.typingStyle)
        view.accessibilityLabel = placeholder
        if isFocused && !view.isFirstResponder {
            view.becomeFirstResponder()
        } else if !isFocused && view.isFirstResponder {
            view.resignFirstResponder()
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: MessageComposerTextView, context: Context) -> CGSize? {
        let width = proposal.width ?? 300
        let measured = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        return CGSize(width: width, height: min(expanded ? 320 : 160, max(44, measured.height)))
    }

    static func dismantleUIView(_ uiView: MessageComposerTextView, coordinator: Coordinator) {
        coordinator.parent.document.applyEdit = nil
    }

    @MainActor
    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: MessageRichTextEditor
        weak var textView: MessageComposerTextView?
        var applying = false

        init(_ parent: MessageRichTextEditor) { self.parent = parent }

        func apply(_ value: NSAttributedString, selection: NSRange) {
            guard let view = textView, view.markedTextRange == nil else { return }
            let old = NSAttributedString(attributedString: view.attributedText)
            let oldSelection = view.selectedRange
            view.undoManager?.registerUndo(withTarget: self) { target in target.apply(old, selection: oldSelection) }
            applying = true
            view.textStorage.setAttributedString(value)
            view.selectedRange = selection
            parent.document.accept(value, selection: selection)
            view.typingAttributes = MessageEditorDocument.attributes(parent.document.typingStyle)
            view.invalidateIntrinsicContentSize()
            applying = false
        }

        func textViewDidChange(_ textView: UITextView) {
            guard !applying, textView.markedTextRange == nil else { return }
            parent.document.accept(textView.attributedText, selection: textView.selectedRange)
            textView.invalidateIntrinsicContentSize()
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard !applying, textView.markedTextRange == nil else { return }
            parent.document.selection = textView.selectedRange
            if textView.selectedRange.length == 0 {
                parent.document.typingStyle = MessageEditorDocument.style(textView.typingAttributes)
                // Never continue reference/link attributes when typing beyond an atom.
                textView.typingAttributes = MessageEditorDocument.attributes(parent.document.typingStyle)
            }
        }

        func textViewDidBeginEditing(_ textView: UITextView) { parent.isFocused = true }
        func textViewDidEndEditing(_ textView: UITextView) { parent.isFocused = false }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            guard textView.markedTextRange == nil else { return true }
            if text.isEmpty, let atom = parent.document.atomicSelectionForDeletion(range) {
                textView.selectedRange = atom
                parent.document.selection = atom
                return false
            }
            return true
        }
    }
}

/// Clipboard data is deliberately Markdown, so references survive copying without replacement glyphs.
final class MessageComposerTextView: UITextView {
    private static let markdownPasteboardType = "de.tum.cit.aet.artemis.message-markdown"
    weak var document: MessageEditorDocument?

    override var keyCommands: [UIKeyCommand]? {
        (super.keyCommands ?? []) + [UIKeyCommand(input: UIKeyCommand.inputEscape, modifierFlags: [], action: #selector(dismissComposer))]
    }

    @objc
    private func dismissComposer() { resignFirstResponder() }

    override func copy(_ sender: Any?) {
        guard let document, selectedRange.length > 0 else { return }
        UIPasteboard.general.setItems([[
            "public.utf8-plain-text": document.plainText(in: selectedRange),
            Self.markdownPasteboardType: Data(document.markdown(in: selectedRange).utf8)
        ]])
    }

    override func cut(_ sender: Any?) {
        copy(sender)
        replaceSelectedWithPlainText("")
    }

    override func paste(_ sender: Any?) {
        if let data = UIPasteboard.general.data(forPasteboardType: Self.markdownPasteboardType) {
            document?.insertMarkup(String(decoding: data, as: UTF8.self))
        } else if let value = UIPasteboard.general.string {
            document?.insertMarkup(value)
        }
    }

    private func replaceSelectedWithPlainText(_ value: String) {
        // Native insertion preserves UIKit undo and never imports foreign attachment objects.
        insertText(value)
    }
}
