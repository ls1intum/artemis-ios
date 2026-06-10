//
//  FlowLayout.swift
//  ArtemisKit
//
//  Created by Viktor Lynok on 09.06.26.
//

import Foundation
import SwiftUI

struct FlowLayout: Layout {
    var spacing: CGFloat

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let availableWidth: CGFloat
        if let width = proposal.width, width != .infinity {
            availableWidth = width
        } else {
            availableWidth = 350
        }
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        return layout(sizes: sizes, proposalWidth: availableWidth).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let availableWidth = bounds.width
        let sizes = subviews.map { $0.sizeThatFits(.unspecified) }
        let layoutData = layout(sizes: sizes, proposalWidth: availableWidth)

        for (index, subview) in subviews.enumerated() {
            let position = layoutData.positions[index]
            let actualPosition = CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y)
            let itemSize = sizes[index]
            
            let constrainedWidth = min(itemSize.width, availableWidth)
            
            subview.place(
                at: actualPosition,
                proposal: ProposedViewSize(width: constrainedWidth, height: itemSize.height)
            )
        }
    }

    private func layout(sizes: [CGSize], proposalWidth: CGFloat) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxRowHeight: CGFloat = 0
        var maxContainerWidth: CGFloat = 0

        for size in sizes {
            let itemWidth = min(size.width, proposalWidth)
            
            if currentX + itemWidth > proposalWidth && currentX > 0 {
                currentX = 0
                currentY += maxRowHeight + spacing
                maxRowHeight = 0
            }

            positions.append(CGPoint(x: currentX, y: currentY))
            maxRowHeight = max(maxRowHeight, size.height)
            currentX += itemWidth + spacing
            maxContainerWidth = max(maxContainerWidth, currentX)
        }

        let finalWidth = max(0, maxContainerWidth - spacing)
        let finalHeight = currentY + maxRowHeight
        return (CGSize(width: finalWidth, height: finalHeight), positions)
    }
}
