import UIKit

struct MessageEditorAttachment: Identifiable, Equatable {
    let range: NSRange
    let name: String
    let path: String
    let isImage: Bool
    var id: Int { range.location }
}

extension MessageEditorDocument {
    var attachments: [MessageEditorAttachment] {
        guard !hasUnsupportedContent else { return [] }
        let range = NSRange(location: 0, length: content.length)
        var result: [MessageEditorAttachment] = []
        content.enumerateAttribute(.attachment, in: range) { value, range, _ in
            guard let reference = (value as? MessageReferenceAttachment)?.reference,
                  let name = reference.imageName ?? reference.fileName, let path = reference.imagePath ?? reference.filePath else { return }
            result.append(MessageEditorAttachment(range: range, name: name, path: path, isImage: reference.imagePath != nil))
        }
        content.enumerateAttribute(.link, in: range) { value, range, _ in
            guard let value else { return }
            let path = String(describing: value)
            guard URLComponents(string: path)?.path.contains("/files/") == true else { return }
            result.append(MessageEditorAttachment(range: range, name: (content.string as NSString).substring(with: range), path: path, isImage: false))
        }
        return result.sorted { $0.range.location < $1.range.location }
    }

    @discardableResult
    func renameAttachment(_ attachment: MessageEditorAttachment, to name: String) -> Bool {
        let name = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !name.isEmpty, name.rangeOfCharacter(from: .newlines.union(.controlCharacters)) == nil,
              attachments.contains(attachment) else { return false }
        var attributes = content.attributes(at: attachment.range.location, effectiveRange: nil)
        let replacement: NSAttributedString
        if attributes[.attachment] != nil {
            let markup = (attachment.isImage ? "!" : "") + MessageEditorCodec.encode([MessageEditorSpan(text: name, link: attachment.path)])
            let reference = MessageEditorReference(markup: markup, label: attachment.isImage ? "Image: " + name : name,
                                                   imageName: attachment.isImage ? name : nil, imagePath: attachment.isImage ? attachment.path : nil,
                                                   fileName: attachment.isImage ? nil : name, filePath: attachment.isImage ? nil : attachment.path)
            attributes[.attachment] = MessageReferenceAttachment(reference: reference)
            replacement = NSAttributedString(string: "\u{fffc}", attributes: attributes)
        } else {
            replacement = NSAttributedString(string: name, attributes: attributes)
        }
        replace(attachment.range, with: replacement)
        return true
    }

    func removeAttachment(_ attachment: MessageEditorAttachment) {
        guard attachments.contains(attachment) else { return }
        replace(attachment.range, with: NSAttributedString(string: ""))
    }
}
