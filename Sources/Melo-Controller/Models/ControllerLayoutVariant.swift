//
//  ControllerLayoutVariant.swift
//  Melo-Controller
//

import SwiftUI

/// Which arrangement of the on-screen controller is showing, decided only from the space the
/// ``ControllerView`` is actually given. It never looks at the device, the screen or the window.
enum ControllerLayoutVariant: String, CaseIterable {
    /// Compact arrangement: the two halves sit close together, with the center buttons underneath.
    case portrait
    /// Spread arrangement: one half at each side with the center buttons between them.
    case landscape

    var title: LocalizedStringKey {
        switch self {
        case .portrait: return "Portrait Layout"
        case .landscape: return "Landscape Layout"
        }
    }

    var systemImage: String {
        switch self {
        case .portrait: return "iphone"
        case .landscape: return "iphone.landscape"
        }
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
    ///   - controllerScale: The user's On-Screen Controller scale.
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
