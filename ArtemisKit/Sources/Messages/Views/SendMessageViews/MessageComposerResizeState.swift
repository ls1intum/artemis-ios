import CoreGraphics

/// Tracks a drag relative to its starting height; the editor also respects its layout proposal.
struct MessageComposerResizeState {
    private(set) var extraHeight: CGFloat = 0
    private var dragStart: CGFloat?

    mutating func update(translation: CGFloat, maximum: CGFloat) {
        if dragStart == nil { dragStart = min(extraHeight, maximum) }
        extraHeight = min(maximum, max(0, (dragStart ?? 0) - translation))
    }

    mutating func finish(translation: CGFloat, horizontalTranslation: CGFloat = 0, maximum: CGFloat) {
        let vertical = abs(translation) > abs(horizontalTranslation) ? translation : 0
        let expand = abs(vertical) >= 24 ? vertical < 0 : extraHeight > maximum / 2
        setExpanded(expand, maximum: maximum)
    }

    mutating func setExpanded(_ expanded: Bool, maximum: CGFloat) {
        extraHeight = expanded ? maximum : 0
        dragStart = nil
    }

    mutating func cancelGesture() { dragStart = nil }
}
