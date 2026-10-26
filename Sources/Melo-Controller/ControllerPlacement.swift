//
//  ControllerPlacement.swift
//  Melo-Controller
//

import SwiftUI

/// Where the on-screen controller can move vertically. ``ControllerView`` publishes it through
/// ``ControllerPlacementKey`` so a host can offer controls that nudge the controller, and stores
/// the offset under ``ControllerLayoutVariant/verticalOffsetKey``.
public struct ControllerPlacement: Equatable, Sendable {
    /// The arrangement showing now. Each arrangement keeps its own offset.
    public var variant: ControllerLayoutVariant
    /// Offsets the controls can take without leaving their pane, in points; negative is up.
    public var offsetRange: ClosedRange<CGFloat>

    public init(variant: ControllerLayoutVariant, offsetRange: ClosedRange<CGFloat>) {
        self.variant = variant
        self.offsetRange = offsetRange
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
