import UIKit

extension MessageRichTextEditor.Coordinator {
    func textView(_ textView: UITextView, editMenuForTextInRanges ranges: [NSValue],
                  suggestedActions: [UIMenuElement]) -> UIMenu? {
        guard ranges.count == 1, let range = ranges.first?.rangeValue,
              range.location != NSNotFound, range.location >= 0,
              NSMaxRange(range) <= parent.document.content.length,
              !parent.document.hasUnsupportedContent else { return nil }
        parent.document.selection = range
        let formats: [(String, String, MessageEditorStyle)] = [
            (R.string.localizable.bold(), "bold", .bold),
            (R.string.localizable.italic(), "italic", .italic),
            (R.string.localizable.underline(), "underline", .underline),
            (R.string.localizable.strikethrough(), "strikethrough", .strikethrough),
            (R.string.localizable.inlineCode(), "curlybraces", .code)
        ]
        let actions = formats.map { title, icon, style in
            UIAction(title: title, image: UIImage(systemName: icon),
                     attributes: parent.document.canFormatInline ? [] : .disabled,
                     state: parent.document.activeStyle.contains(style) ? .on : .off) { [weak self] _ in
                guard let self else { return }
                self.parent.document.toggle(style)
            }
        }
        let formatting = UIMenu(title: R.string.localizable.textFormatting(), image: UIImage(systemName: "textformat"), children: actions)
        return UIMenu(children: suggestedActions + [formatting])
    }
}
