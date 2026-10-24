import UIKit

/// Draw block backgrounds in text-container coordinates so they follow wrapping, scrolling and resizing.
final class MessageComposerLayoutManager: NSLayoutManager {
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard let textStorage else { return }
        enumerateLineFragments(forGlyphRange: glyphsToShow) { rect, _, container, glyphs, _ in
            let characters = self.characterRange(forGlyphRange: glyphs, actualGlyphRange: nil)
            guard characters.location < textStorage.length else { return }
            let style = textStorage.attribute(.messageBlock, at: characters.location, effectiveRange: nil) as? String
            let padding = container.lineFragmentPadding
            if style == MessageEditorBlockStyle.codeBlock.rawValue {
                let background = CGRect(x: origin.x + rect.minX + padding, y: origin.y + rect.minY,
                                        width: rect.width - 2 * padding, height: rect.height)
                UIColor.secondarySystemFill.setFill()
                UIRectFill(background)
            } else if style == MessageEditorBlockStyle.quote.rawValue {
                let rule = CGRect(x: origin.x + padding + 2, y: origin.y + rect.minY, width: 3, height: rect.height)
                UIColor.secondaryLabel.setFill()
                UIRectFill(rule)
            }
        }
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
    }
}
