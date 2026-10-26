//
//  FoldClearance.swift
//  Melo-Controller
//

import CoreGraphics

/// Works out how far the controller's center buttons have to move away from the keep-clear
/// regions the app passes in (see ``EnvironmentValues/controllerKeepClearRegions``).
struct FoldClearance {
    /// Distance kept between a button's drawing and a region.
    static let margin: CGFloat = 8

    let paneSize: CGSize
    let regions: [CGRect]

    /// Regions shaped like a fold: moving buttons sideways can clear these. Wide and short regions
    /// (a fold lying across the pane) are ignored.
    var dividers: [CGRect] {
        let pane = CGRect(origin: .zero, size: paneSize)
        return regions.filter { region in
            !region.isNull && !region.isEmpty && region.intersects(pane)
                && region.width < paneSize.width / 2 && region.height >= region.width
        }
    }

    /// Width of the widest divider that crosses the middle of the pane (the zone the center buttons
    /// use), or 0. The spread layout only fits around it if the pane leaves that much extra room.
    var centerFoldWidth: CGFloat {
        let center = paneSize.width / 2
        let zone = (center - ControllerLayoutVariant.halfWidth / 2)...(center + ControllerLayoutVariant.halfWidth / 2)
        return dividers.filter { $0.maxX > zone.lowerBound && $0.minX < zone.upperBound }.map(\.width).max() ?? 0
    }

    /// The gap two halves that sit symmetrically about the pane's center need so that no divider
    /// crossing the middle covers them. For a divider centered on the pane that is its width plus
    /// twice the margin. The result stays at `base` when nothing crosses the middle and never
    /// exceeds `limit` (the room actually available), unless `base` already does.
    func centeredGap(base: CGFloat, extraMargin: CGFloat = 0, limit: CGFloat) -> CGFloat {
        let center = paneSize.width / 2
        var reach: CGFloat = 0
        for divider in dividers where divider.maxX > center - base / 2 && divider.minX < center + base / 2 {
            reach = max(reach, abs(divider.minX - center), abs(divider.maxX - center))
        }
        guard reach > 0 else { return base }
        let needed = 2 * (reach + Self.margin + extraMargin)
        return min(max(base, needed), max(base, limit))
    }

    /// The horizontal span, relative to the pane's center, that the center buttons must stay out of,
    /// or nil when no divider is present.
    func span(extraMargin: CGFloat = 0) -> ClosedRange<CGFloat>? {
        let center = paneSize.width / 2
        let dividers = dividers
        guard let low = dividers.map(\.minX).min(), let high = dividers.map(\.maxX).max() else { return nil }
        let margin = Self.margin + extraMargin
        return (low - center - margin)...(high - center + margin)
    }
}
