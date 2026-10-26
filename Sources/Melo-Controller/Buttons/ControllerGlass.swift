//
//  ControllerGlass.swift
//  Melo-Controller
//

import SwiftUI

/// Whether the on-screen controller draws with Liquid Glass: the user's setting
/// (`On-ScreenControllerGlass`, on by default), unless Reduce Transparency is on.
struct ControllerGlassPreference: DynamicProperty {
    @AppStorage("On-ScreenControllerGlass") private var isEnabled = true
    @Environment(\.accessibilityReduceTransparency) private var reduceTransparency

    var isActive: Bool { isEnabled && !reduceTransparency }
}

/// One control drawn as clear glass over a light dimming fill, so it stays legible on bright game
/// frames. The symbol is the glass view's own content: glass inside a `GlassEffectContainer` refracts
/// everything drawn under it, so a symbol placed beside the glass would come out distorted.
///
/// The surface never takes touches (the UIKit touch views above it do) and is deliberately not
/// `interactive`; a press is shown through `isPressed` instead.
struct ControllerGlassSurface<S: Shape, Content: View>: View {
    let shape: S
    var isPressed = false
    @ViewBuilder var content: Content

    var body: some View {
        content
            .glassEffect(isPressed ? .clear.tint(.white.opacity(0.35)) : .clear, in: shape)
            .background(shape.fill(Color.black.opacity(0.25)))
            .allowsHitTesting(false)
    }
}
