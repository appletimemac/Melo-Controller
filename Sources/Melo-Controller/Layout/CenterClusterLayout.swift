//
//  CenterClusterLayout.swift
//  Melo-Controller
//

import SwiftUI

/// Lays out the two halves of the center buttons (Minus with L3 on the leading side, Plus with R3
/// on the trailing side). Without a clearance it behaves like a flexible row that keeps its halves
/// at the two ends. With one, a half that overlaps the span moves just far enough to stand beside
/// it (inside the layout's own bounds), so the halves split around a fold while everything else
/// stays where it is.
struct CenterClusterLayout: Layout {
    /// Smallest gap between the halves: the two 50 pt gaps around the spacer the row used to have.
    static let minimumGap: CGFloat = 100

    /// Span relative to this layout's center that neither half may cover. The layout is centered
    /// between the two side columns, which is the pane's center.
    var clearance: ClosedRange<CGFloat>?

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        guard subviews.count == 2 else { return .zero }
        let leading = subviews[0].sizeThatFits(.unspecified)
        let trailing = subviews[1].sizeThatFits(.unspecified)
        let minimumWidth = leading.width + Self.minimumGap + trailing.width
        return CGSize(
            width: max(minimumWidth, proposal.width ?? minimumWidth),
            height: max(leading.height, trailing.height)
        )
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        guard subviews.count == 2 else { return }
        let leading = subviews[0].sizeThatFits(.unspecified)
        let trailing = subviews[1].sizeThatFits(.unspecified)

        var leadingX = bounds.minX
        var trailingX = bounds.maxX - trailing.width

        if let clearance {
            let low = bounds.midX + clearance.lowerBound
            let high = bounds.midX + clearance.upperBound
            // A half never leaves this layout's bounds: past them it would land on a side column.
            if leadingX + leading.width > low && leadingX < high {
                leadingX = max(bounds.minX, low - leading.width)
            }
            if trailingX < high && trailingX + trailing.width > low {
                trailingX = min(bounds.maxX - trailing.width, high)
            }
        }

        subviews[0].place(at: CGPoint(x: leadingX, y: bounds.minY), anchor: .topLeading, proposal: ProposedViewSize(leading))
        subviews[1].place(at: CGPoint(x: trailingX, y: bounds.minY), anchor: .topLeading, proposal: ProposedViewSize(trailing))
    }
}
