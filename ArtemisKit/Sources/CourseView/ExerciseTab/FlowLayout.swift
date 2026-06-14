//
//  FlowLayout.swift
//  ArtemisKit
//
//  Created by Viktor Lynok on 09.06.26.
//

import Foundation
import SwiftUI

/// A custom layout that arranges subviews horizontally and wraps them into multiple rows
/// if they exceed the available container width (similar to CSS flex-wrap).
struct FlowLayout: Layout {
    var spacing: CGFloat
    
    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let availableWidth: CGFloat
        if let width = proposal.width, width != .infinity {
            availableWidth = width
        } else {
            availableWidth = 350 // Safe fallback width to properly calculate row wrapping and height
        }
        // Requests the ideal (unconstrained) size of each subview
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
            
            // Forces the subview to stay within the container boundaries to trigger native text truncation (...)
            let constrainedWidth = min(itemSize.width, availableWidth)
            
            subview.place(
                at: actualPosition,
                proposal: ProposedViewSize(width: constrainedWidth, height: itemSize.height)
            )
        }
    }
    
    /// Core math engine that calculates the total container size and absolute coordinates for each subview.
    private func layout(sizes: [CGSize], proposalWidth: CGFloat) -> (size: CGSize, positions: [CGPoint]) {
        var positions: [CGPoint] = []
        var currentX: CGFloat = 0
        var currentY: CGFloat = 0
        var maxRowHeight: CGFloat = 0
        var maxContainerWidth: CGFloat = 0
        
        for size in sizes {
            // Ensures a single massive item doesn't break row calculation logic
            let itemWidth = min(size.width, proposalWidth)
            // Wraps to the next line if the current item exceeds the remaining row capacity
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
        // Calculates final layout dimensions, safely removing the trailing spacing offset
        let finalWidth = max(0, maxContainerWidth - spacing)
        let finalHeight = currentY + maxRowHeight
        return (CGSize(width: finalWidth, height: finalHeight), positions)
    }
}
