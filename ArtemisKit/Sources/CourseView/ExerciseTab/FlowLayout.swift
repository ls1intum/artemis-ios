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
    var isCentered: Bool = false

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
        var positions = [CGPoint](repeating: .zero, count: sizes.count)

        // Step 1: Group items into rows
        var rows: [[(index: Int, size: CGSize)]] = []
        var currentRow: [(index: Int, size: CGSize)] = []
        var currentX: CGFloat = 0

        for (index, size) in sizes.enumerated() {
            let itemWidth = min(size.width, proposalWidth)

            // Wraps to the next line if the current item exceeds the remaining row capacity
            if currentX + itemWidth > proposalWidth && !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = []
                currentX = 0
            }

            currentRow.append((index, CGSize(width: itemWidth, height: size.height)))
            currentX += itemWidth + spacing
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        // Step 2: Place rows and handle alignment (left, center, or space-between)
        var currentY: CGFloat = 0
        var maxContainerWidth: CGFloat = 0

        for row in rows {
            let rowHeight = row.map { $0.size.height }.max() ?? 0
            let totalItemsWidth = row.map { $0.size.width }.reduce(0, +)
            let baseSpacing = spacing

            let rowCount = row.count
            let rowWidth = totalItemsWidth + CGFloat(max(0, rowCount - 1)) * baseSpacing

            // Calculate start X position and spacing for current row
            var xOffset: CGFloat = 0
            var actualSpacing = baseSpacing

            if isCentered {
                if rowCount == 1 {
                    // Single element, center in row
                    xOffset = max(0, (proposalWidth - row[0].size.width) / 2)
                } else {
                    // space-between: first at left, last at right, rest spread evenly
                    let extraSpace = max(0, proposalWidth - totalItemsWidth)
                    actualSpacing = rowCount > 1 ? extraSpace / CGFloat(rowCount - 1) : 0
                    xOffset = 0
                }
            } else {
                xOffset = 0
                actualSpacing = baseSpacing
            }

            var itemX = xOffset
            for item in row {
                positions[item.index] = CGPoint(x: itemX, y: currentY)
                itemX += item.size.width + actualSpacing
            }

            // For container width, use proposalWidth if centered, otherwise actual row width
            let finalRowWidth: CGFloat
            if isCentered && rowCount > 1 {
                finalRowWidth = proposalWidth
            } else {
                finalRowWidth = itemX - actualSpacing // Remove last spacing
            }
            maxContainerWidth = max(maxContainerWidth, finalRowWidth)
            currentY += rowHeight + spacing
        }

        // Calculates final layout dimensions, safely removing the trailing spacing offset
        let finalWidth = max(0, maxContainerWidth)
        let finalHeight = max(0, currentY - spacing)

        return (CGSize(width: finalWidth, height: finalHeight), positions)
    }
}
