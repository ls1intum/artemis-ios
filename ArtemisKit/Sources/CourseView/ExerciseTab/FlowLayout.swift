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
        return layout(subviews: subviews, proposalWidth: availableWidth).size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let availableWidth = bounds.width
        let layoutData = layout(subviews: subviews, proposalWidth: availableWidth)

        for (index, subview) in subviews.enumerated() {
            let position = layoutData.positions[index]
            let actualPosition = CGPoint(x: bounds.minX + position.x, y: bounds.minY + position.y)
            let itemSize = layoutData.sizes[index]

            subview.place(
                at: actualPosition,
                proposal: ProposedViewSize(width: itemSize.width, height: itemSize.height)
            )
        }
    }

    /// Core math engine that calculates the total container size, sizes, and absolute coordinates for each subview.
    private func layout(subviews: Subviews, proposalWidth: CGFloat) -> (size: CGSize, positions: [CGPoint], sizes: [CGSize]) {
        var positions = [CGPoint](repeating: .zero, count: subviews.count)
        var finalSizes = [CGSize](repeating: .zero, count: subviews.count)

        // Step 1: Group items into rows using their ideal widths
        var rows: [[(index: Int, idealSize: CGSize, subview: LayoutSubview)]] = []
        var currentRow: [(index: Int, idealSize: CGSize, subview: LayoutSubview)] = []
        var currentX: CGFloat = 0

        for (index, subview) in subviews.enumerated() {
            let idealSize = subview.sizeThatFits(.unspecified)
            let itemWidth = min(idealSize.width, proposalWidth)

            // Wraps to the next line if the current item exceeds the remaining row capacity
            if currentX + itemWidth > proposalWidth && !currentRow.isEmpty {
                rows.append(currentRow)
                currentRow = []
                currentX = 0
            }

            currentRow.append((index, idealSize, subview))
            currentX += itemWidth + spacing
        }

        if !currentRow.isEmpty {
            rows.append(currentRow)
        }

        // Step 2: Place rows and handle stretching or standard alignment
        var currentY: CGFloat = 0
        var maxContainerWidth: CGFloat = 0

        for row in rows {
            let rowCount = row.count
            let totalSpacing = CGFloat(max(0, rowCount - 1)) * spacing
            let totalIdealWidth = row.map { $0.idealSize.width }.reduce(0, +)

            var rowItems: [(index: Int, size: CGSize)] = []

            if isCentered {
                // Stretch items to fill the remaining width of the container
                let extraSpace = max(0, proposalWidth - (totalIdealWidth + totalSpacing))
                let widthAddition = extraSpace / CGFloat(rowCount)

                for item in row {
                    let stretchedWidth = item.idealSize.width + widthAddition
                    // Query the height with the newly calculated stretched width
                    let sizeWithStretchedWidth = item.subview.sizeThatFits(ProposedViewSize(width: stretchedWidth, height: nil))
                    rowItems.append((item.index, CGSize(width: stretchedWidth, height: sizeWithStretchedWidth.height)))
                }
            } else {
                // Keep ideal widths but constrain them to proposalWidth to prevent overflow
                for item in row {
                    let constrainedWidth = min(item.idealSize.width, proposalWidth)
                    let sizeWithConstrainedWidth = item.subview.sizeThatFits(ProposedViewSize(width: constrainedWidth, height: nil))
                    rowItems.append((item.index, CGSize(width: constrainedWidth, height: sizeWithConstrainedWidth.height)))
                }
            }

            let rowHeight = rowItems.map { $0.size.height }.max() ?? 0

            var itemX: CGFloat = 0
            for item in rowItems {
                positions[item.index] = CGPoint(x: itemX, y: currentY)
                finalSizes[item.index] = item.size
                itemX += item.size.width + spacing
            }

            let finalRowWidth = max(0, itemX - spacing)
            maxContainerWidth = max(maxContainerWidth, finalRowWidth)
            currentY += rowHeight + spacing
        }

        // Calculates final layout dimensions, safely removing the trailing spacing offset
        let finalWidth = max(0, maxContainerWidth)
        let finalHeight = max(0, currentY - spacing)

        return (CGSize(width: finalWidth, height: finalHeight), positions, finalSizes)
    }
}
