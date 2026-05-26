//
//  TwoColumnLayout.swift
//  ArtemisKit
//
//  Created by Anian Schleyer on 03.05.26.
//

import SwiftUI

/// Layout that fills two colums greedily, i.e. adds views iteratively to the smaller column
struct TwoColumnLayout: Layout {
    let spacing: CGFloat = .m

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let width = proposal.width ?? 0
        let columnWidth = if subviews.count == 1 {
            width // Use full width if only one view needs to be placed
        } else {
            (width - spacing) / 2
        }

        var leftHeight: CGFloat = 0
        var rightHeight: CGFloat = 0

        for subview in subviews {
            let size = subview.sizeThatFits(.init(width: columnWidth, height: nil))

            if leftHeight <= rightHeight {
                leftHeight += size.height + spacing
            } else {
                rightHeight += size.height + spacing
            }
        }

        return CGSize(width: width, height: max(leftHeight, rightHeight))
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let columnWidth = if subviews.count == 1 {
            bounds.width // Use full width if only one view needs to be placed
        } else {
            (bounds.width - spacing) / 2
        }

        var leftY: CGFloat = bounds.minY
        var rightY: CGFloat = bounds.minY

        for subview in subviews {
            let size = subview.sizeThatFits(.init(width: columnWidth, height: nil))

            if leftY <= rightY {
                subview.place(at: CGPoint(x: bounds.minX, y: leftY),
                              proposal: ProposedViewSize(width: columnWidth, height: size.height))
                leftY += size.height + spacing
            } else {
                subview.place(at: CGPoint(x: bounds.minX + columnWidth + spacing, y: rightY),
                              proposal: ProposedViewSize(width: columnWidth, height: size.height))
                rightY += size.height + spacing
            }
        }
    }
}
