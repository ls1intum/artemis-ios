import SwiftUI
import UIKit

/// UIKit keeps native selection, IME composition and undo while the document stores wire Markdown.
struct MessageRichTextEditor: UIViewRepresentable {
    var document: MessageEditorDocument
    var placeholder: String
    @Binding var isFocused: Bool
    var expanded: Bool
    var showsCompletions = false
    @Environment(\.verticalSizeClass) private var verticalSizeClass

    func makeCoordinator() -> Coordinator { Coordinator(self) }

    func makeUIView(context: Context) -> MessageComposerTextView {
        let view = MessageComposerTextView()
        view.document = document
        view.isEditable = !document.hasUnsupportedContent
        view.backgroundColor = .secondarySystemBackground
        view.layer.cornerRadius = 8
        view.textContainerInset = UIEdgeInsets(top: 12, left: 4, bottom: 12, right: 4)
        view.adjustsFontForContentSizeCategory = true
        view.allowsEditingTextAttributes = false
        view.accessibilityIdentifier = "message-rich-text-editor"
        view.accessibilityLabel = placeholder
        view.font = .preferredFont(forTextStyle: .body)
        view.attributedText = document.content
        view.selectedRange = document.selection
        view.typingAttributes = document.typingAttributes
        view.updateTypingTraits(for: document)
        view.delegate = context.coordinator
        context.coordinator.textView = view
        document.applyEdit = { [weak coordinator = context.coordinator] value, range in coordinator?.apply(value, selection: range) }
        document.applyTypingAttributes = { [weak coordinator = context.coordinator] in coordinator?.refreshTypingAttributes() }
        return view
    }

    func updateUIView(_ view: MessageComposerTextView, context: Context) {
        if view.document !== document {
            view.document?.applyEdit = nil
            view.document?.applyTypingAttributes = nil
            view.document = document
            document.applyEdit = { [weak coordinator = context.coordinator] value, range in coordinator?.apply(value, selection: range) }
            document.applyTypingAttributes = { [weak coordinator = context.coordinator] in coordinator?.refreshTypingAttributes() }
        }
        context.coordinator.parent = self
        guard view.markedTextRange == nil else { return }
        context.coordinator.applying = true
        defer { context.coordinator.applying = false }
        view.isEditable = !document.hasUnsupportedContent
        if !view.attributedText.isEqual(to: document.content) {
            view.attributedText = document.content
            view.invalidateIntrinsicContentSize()
        }
        if view.selectedRange != document.selection { view.selectedRange = document.selection }
        view.typingAttributes = document.typingAttributes
        view.updateTypingTraits(for: document)
        view.accessibilityLabel = placeholder
        if isFocused && !document.hasUnsupportedContent && !view.isFirstResponder {
            view.becomeFirstResponder()
        } else if (!isFocused || document.hasUnsupportedContent) && view.isFirstResponder {
            view.resignFirstResponder()
        }
    }

    func sizeThatFits(_ proposal: ProposedViewSize, uiView: MessageComposerTextView, context: Context) -> CGSize? {
        let width = proposal.width ?? 300
        let measured = uiView.sizeThatFits(CGSize(width: width, height: .greatestFiniteMagnitude))
        let compact = verticalSizeClass == .compact
        let maximum: CGFloat = showsCompletions ? (compact ? 44 : 80) : expanded ? (compact ? 120 : 320) : (compact ? 80 : 160)
        let minimum: CGFloat = expanded && !showsCompletions ? (compact ? 100 : 200) : 44
        // VStack probes with zero height to learn our minimum. Honouring that proposal here
        // would report 44 points even when expanded, preventing it from allocating writing space.
        return CGSize(width: width, height: min(maximum, max(minimum, measured.height)))
    }

    static func dismantleUIView(_ uiView: MessageComposerTextView, coordinator: Coordinator) {
        uiView.delegate = nil
        uiView.document?.applyEdit = nil
        uiView.document?.applyTypingAttributes = nil
        uiView.document = nil
    }

    @MainActor
    final class Coordinator: NSObject, UITextViewDelegate {
        var parent: MessageRichTextEditor
        weak var textView: MessageComposerTextView?
        var applying = false

        init(_ parent: MessageRichTextEditor) { self.parent = parent }

        func refreshTypingAttributes() {
            guard let view = textView, view.markedTextRange == nil else { return }
            let wasApplying = applying
            applying = true
            view.typingAttributes = parent.document.typingAttributes
            view.updateTypingTraits(for: parent.document)
            applying = wasApplying
        }

        func apply(_ value: NSAttributedString, selection: NSRange) {
            guard !parent.document.hasUnsupportedContent, let view = textView, view.markedTextRange == nil else { return }
            let old = NSAttributedString(attributedString: view.attributedText)
            let oldSelection = view.selectedRange
            view.undoManager?.registerUndo(withTarget: self) { target in target.apply(old, selection: oldSelection) }
            applying = true
            view.textStorage.setAttributedString(value)
            view.selectedRange = selection
            parent.document.accept(value, selection: selection)
            view.typingAttributes = parent.document.typingAttributes
            view.updateTypingTraits(for: parent.document)
            view.invalidateIntrinsicContentSize()
            applying = false
        }

        func textViewDidChange(_ textView: UITextView) {
            guard !applying, textView.markedTextRange == nil else { return }
            parent.document.accept(textView.attributedText, selection: textView.selectedRange)
            textView.typingAttributes = parent.document.typingAttributes
            textView.invalidateIntrinsicContentSize()
        }

        func textViewDidChangeSelection(_ textView: UITextView) {
            guard !applying, textView.markedTextRange == nil else { return }
            let moved = parent.document.selection != textView.selectedRange
            // UIKit can advance the caret before textViewDidChange. Derive the next typing
            // attributes from the new content rather than an out-of-bounds old selection.
            let edited = !parent.document.content.isEqual(to: textView.attributedText)
            if edited {
                parent.document.accept(textView.attributedText, selection: textView.selectedRange)
            } else {
                parent.document.selection = textView.selectedRange
            }
            if textView.selectedRange.length == 0 {
                if moved && !edited, textView.attributedText.length > 0 {
                    let caret = textView.selectedRange.location
                    let paragraph = (textView.attributedText.string as NSString).paragraphRange(for: textView.selectedRange)
                    let index = caret == paragraph.location ? caret : caret - 1
                    parent.document.typingStyle = index < textView.attributedText.length
                        ? MessageEditorDocument.style(textView.attributedText.attributes(at: index, effectiveRange: nil)) : []
                }
                // Preserve an explicitly selected typing style across native attribute normalization,
                // while never continuing reference/link attributes beyond an atom.
                textView.typingAttributes = parent.document.typingAttributes
            }
        }

        func textViewDidBeginEditing(_ textView: UITextView) {
            guard !applying, !parent.isFocused else { return }
            parent.isFocused = true
        }

        func textViewDidEndEditing(_ textView: UITextView) {
            guard !applying, parent.isFocused else { return }
            parent.isFocused = false
        }

        func textView(_ textView: UITextView, shouldChangeTextIn range: NSRange, replacementText text: String) -> Bool {
            guard !parent.document.hasUnsupportedContent else { return false }
            guard textView.markedTextRange == nil else { return true }
            if text.isEmpty, let atom = parent.document.atomicSelectionForDeletion(range) {
                textView.selectedRange = atom
                parent.document.selection = atom
                return false
            }
            return !parent.document.handleReplacement(in: range, text: text)
        }
    }
}

/// Clipboard data is deliberately Markdown, so references survive copying without replacement glyphs.
final class MessageComposerTextView: UITextView {
    private static let markdownPasteboardType = "de.tum.cit.aet.artemis.message-markdown"
    weak var document: MessageEditorDocument?

    override init(frame: CGRect = .zero, textContainer: NSTextContainer? = nil) {
        if let textContainer {
            super.init(frame: frame, textContainer: textContainer)
        } else {
            let storage = NSTextStorage()
            let layout = MessageComposerLayoutManager()
            let container = NSTextContainer(size: .zero)
            container.widthTracksTextView = true
            storage.addLayoutManager(layout)
            layout.addTextContainer(container)
            super.init(frame: frame, textContainer: container)
        }
    }

    required init?(coder: NSCoder) { super.init(coder: coder) }

    func updateTypingTraits(for document: MessageEditorDocument) {
        let code = document.activeBlockStyle == .codeBlock || document.typingStyle.contains(.code)
        let correction: UITextAutocorrectionType = code ? .no : .default
        guard autocorrectionType != correction else { return }
        autocorrectionType = correction
        autocapitalizationType = code ? .none : .sentences
        spellCheckingType = code ? .no : .default
        smartQuotesType = code ? .no : .default
        smartDashesType = code ? .no : .default
        smartInsertDeleteType = code ? .no : .default
        if isFirstResponder { reloadInputViews() }
    }

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
