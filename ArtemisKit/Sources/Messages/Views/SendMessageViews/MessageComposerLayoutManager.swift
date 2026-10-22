import UIKit

/// Draw block backgrounds in text-container coordinates so they follow wrapping, scrolling and resizing.
final class MessageComposerLayoutManager: NSLayoutManager {
    override func drawBackground(forGlyphRange glyphsToShow: NSRange, at origin: CGPoint) {
        guard let textStorage else { return }
        enumerateLineFragments(forGlyphRange: glyphsToShow) { rect, _, container, glyphs, _ in
            let characters = self.characterRange(forGlyphRange: glyphs, actualGlyphRange: nil)
            guard characters.location < textStorage.length,
                  textStorage.attribute(.messageBlock, at: characters.location, effectiveRange: nil) as? String == MessageEditorBlockStyle.codeBlock.rawValue else { return }
            let padding = container.lineFragmentPadding
            let background = CGRect(x: origin.x + rect.minX + padding, y: origin.y + rect.minY,
                                    width: rect.width - 2 * padding, height: rect.height)
            UIColor.secondarySystemFill.setFill()
            UIRectFill(background)
        }
        super.drawBackground(forGlyphRange: glyphsToShow, at: origin)
    }
}
