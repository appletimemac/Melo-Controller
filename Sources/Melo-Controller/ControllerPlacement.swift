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
    /// Every size a host may offer. ``availableScales`` narrows it for the arrangement showing.
    public static let scaleRange: ClosedRange<CGFloat> = 0.5...2.0

    /// The arrangement showing now. Each arrangement keeps its own offset and size.
    public var variant: ControllerLayoutVariant
    /// Offsets the controls can take without leaving their pane, in points; negative is up.
    public var offsetRange: ClosedRange<CGFloat>
    /// The size the arrangement is drawn at.
    public var scale: CGFloat
    /// Sizes the arrangement showing can take in this pane, matching the layout editor's
    /// Controller Size slider. The spread arrangement stops at the largest size that still fits:
    /// past it the pane would switch to the compact arrangement, and the spread size could no
    /// longer be changed from there.
    public var availableScales: ClosedRange<CGFloat>

    public init(
        variant: ControllerLayoutVariant,
        offsetRange: ClosedRange<CGFloat>,
        scale: CGFloat,
        availableScales: ClosedRange<CGFloat> = scaleRange
    ) {
        self.variant = variant
        self.offsetRange = offsetRange
        self.scale = scale
        self.availableScales = availableScales
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
