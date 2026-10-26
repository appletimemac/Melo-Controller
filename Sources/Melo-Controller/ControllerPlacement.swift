//
//  ControllerPlacement.swift
//  Melo-Controller
//

import SwiftUI

/// Where the on-screen controller sits and how large it is. ``ControllerView`` publishes it through
/// ``ControllerPlacementKey`` so a host can offer controls that move and resize the controller, and
/// reads the values from ``ControllerLayoutVariant/verticalOffsetKey`` and
/// ``ControllerLayoutVariant/scaleKey``.
public struct ControllerPlacement: Equatable, Sendable {
    /// Sizes a host should offer, matching the layout editor's Controller Size slider.
    public static let scaleRange: ClosedRange<CGFloat> = 0.5...2.0

    /// The arrangement showing now. Each arrangement keeps its own offset and size.
    public var variant: ControllerLayoutVariant
    /// Offsets the controls can take without leaving their pane, in points; negative is up.
    public var offsetRange: ClosedRange<CGFloat>
    /// The size the arrangement is drawn at.
    public var scale: CGFloat

    public init(variant: ControllerLayoutVariant, offsetRange: ClosedRange<CGFloat>, scale: CGFloat) {
        self.variant = variant
        self.offsetRange = offsetRange
        self.scale = scale
    }

    /// The offset the controller actually uses for a stored one. A pane smaller than the one the
    /// offset was set in narrows the range, and the stored value is kept for when it grows back.
    public func clamp(_ offset: CGFloat) -> CGFloat {
        min(max(offset, offsetRange.lowerBound), offsetRange.upperBound)
    }
}

/// Carries the ``ControllerPlacement`` of the ``ControllerView`` below, or nil when none is showing.
public struct ControllerPlacementKey: PreferenceKey {
    public static let defaultValue: ControllerPlacement? = nil

    public static func reduce(value: inout ControllerPlacement?, nextValue: () -> ControllerPlacement?) {
        value = nextValue() ?? value
    }
}
