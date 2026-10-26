//
//  ControllerLayoutVariant.swift
//  Melo-Controller
//

import CoreGraphics

/// Which arrangement of the on-screen controller is showing, decided only from the space the
/// ``ControllerView`` is actually given. It never looks at the device, the screen or the window.
enum ControllerLayoutVariant: String, CaseIterable {
    /// Compact arrangement: the two halves sit close together, with the center buttons underneath.
    case portrait
    /// Spread arrangement: one half at each side with the center buttons between them.
    case landscape

    /// Width of one half of the controller at scale 1 (the shoulder row and the stick).
    static let halfWidth: CGFloat = 160
    /// Room the spread arrangement needs between the two halves for the center buttons.
    static let centerWidth: CGFloat = 200

    init(paneSize: CGSize, controllerScale: CGFloat) {
        // The stick keeps its 160 pt layout frame when scaled down (only its drawing shrinks), so a half is
        // never narrower than 160 pt.
        let spreadWidth = 2 * Self.halfWidth * max(controllerScale, 1) + Self.centerWidth
        let isSpread = paneSize.width >= paneSize.height && paneSize.width >= spreadWidth
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
