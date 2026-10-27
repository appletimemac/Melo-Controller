//
//  ControllerLayoutVariant.swift
//  Melo-Controller
//

import SwiftUI

/// Which arrangement of the on-screen controller is showing, decided only from the space the
/// ``ControllerView`` is actually given. It never looks at the device, the screen or the window.
public enum ControllerLayoutVariant: String, CaseIterable, Sendable {
    /// Compact arrangement: the two halves sit close together, with the center buttons underneath.
    case portrait
    /// Spread arrangement: one half at each side with the center buttons between them.
    case landscape

    public var title: LocalizedStringKey {
        switch self {
        case .portrait: return "Portrait Layout"
        case .landscape: return "Landscape Layout"
        }
    }

    public var systemImage: String {
        switch self {
        case .portrait: return "iphone"
        case .landscape: return "iphone.landscape"
        }
    }

    /// The user default holding this arrangement's vertical offset in points (negative is up),
    /// shared by every game.
    public var verticalOffsetKey: String {
        "On-ScreenControllerOffset-\(rawValue)"
    }

    /// The user default holding this arrangement's controller size, shared by every game. While it is
    /// absent the arrangement uses the `On-ScreenControllerScale` default.
    public var scaleKey: String {
        "On-ScreenControllerScale-\(rawValue)"
    }

    /// Width of one half of the controller at scale 1 (the shoulder row and the stick).
    static let halfWidth: CGFloat = 160

    /// Room the spread arrangement needs between the two halves for the center buttons.
    static func centerWidth(controllerScale: CGFloat, stickButtons: Bool) -> CGFloat {
        // With the stick buttons each side of the row grows by a padded L3 or R3.
        stickButtons ? max(200, 140 + 2 * (45 * controllerScale + 32)) : 200
    }

    /// - Parameters:
    ///   - paneSize: The space the controller is laid out in.
    ///   - controllerScale: The spread arrangement's controller size, since the spread arrangement is
    ///     only chosen when it fits at its own size.
    ///   - stickButtons: Whether the L3 and R3 buttons are shown beside Minus and Plus.
    ///   - foldWidth: Width of a fold that crosses the middle of the pane, which the center buttons
    ///     must also fit around (see ``FoldClearance/centerFoldWidth``).
    init(paneSize: CGSize, controllerScale: CGFloat, stickButtons: Bool = false, foldWidth: CGFloat = 0) {
        // The stick keeps its 160 pt layout frame when scaled down (only its drawing shrinks), so a half is
        // never narrower than 160 pt.
        let halves = 2 * Self.halfWidth * max(controllerScale, 1)
        let center = Self.centerWidth(controllerScale: controllerScale, stickButtons: stickButtons)
        let fold = foldWidth > 0 ? foldWidth + 2 * FoldClearance.margin : 0
        let isSpread = paneSize.width >= paneSize.height && paneSize.width >= halves + center + fold
        self = isSpread ? .landscape : .portrait
    }

    /// The height the compact arrangement takes at a size, padding included, so a host can tell
    /// whether a band below the game is tall enough for it.
    public static func compactHeight(controllerScale: CGFloat, stickButtons: Bool) -> CGFloat {
        // Shoulder row, 15, the stick (which keeps its 160 pt frame when scaled down) or D-pad, 20,
        // then Minus and Plus, or the padded L3 and R3 beside them; 16 pt of padding at each end.
        let bottomRow = stickButtons ? 45 * controllerScale + 32 : 35 * controllerScale
        return 32 + 20 * controllerScale + 15 + max(160, 145 * controllerScale) + 20 + bottomRow
    }

    /// The largest size in `sizes` at which the spread arrangement still fits the pane, rounded
    /// down to a whole percent, or nil when it does not fit even at the smallest.
    static func largestSpreadScale(
        in sizes: ClosedRange<CGFloat>,
        paneSize: CGSize,
        stickButtons: Bool,
        foldWidth: CGFloat
    ) -> CGFloat? {
        func fits(_ scale: CGFloat) -> Bool {
            Self(paneSize: paneSize, controllerScale: scale, stickButtons: stickButtons, foldWidth: foldWidth) == .landscape
        }
        guard fits(sizes.lowerBound) else { return nil }
        if fits(sizes.upperBound) { return sizes.upperBound }
        // The width the spread arrangement needs only grows with its size, so the sizes that fit
        // end at a single edge.
        var low = sizes.lowerBound
        var high = sizes.upperBound
        for _ in 0..<20 {
            let mid = (low + high) / 2
            if fits(mid) { low = mid } else { high = mid }
        }
        // The search reaches an edge that falls on a whole percent only from below.
        var percent = (low * 100).rounded(.down)
        if fits((percent + 1) / 100) { percent += 1 }
        return min(sizes.upperBound, max(sizes.lowerBound, percent / 100))
    }
}

/// The two stored layouts of one game (or of the default), one per variant.
struct VariantLayouts: Equatable {
    var portrait = LayoutConfig()
    var landscape = LayoutConfig()

    subscript(variant: ControllerLayoutVariant) -> LayoutConfig {
        get {
            switch variant {
            case .portrait: return portrait
            case .landscape: return landscape
            }
        }
        set {
            switch variant {
            case .portrait: portrait = newValue
            case .landscape: landscape = newValue
            }
        }
    }
}
