//
//  ControllerEnvironment.swift
//  Melo-Controller
//

import SwiftUI

public extension EnvironmentValues {
    /// Rectangles the controls should keep clear of, such as the fold on a foldable iPhone.
    ///
    /// Each rectangle is in the ``ControllerView``'s own coordinate space: the origin is the
    /// view's top-leading corner, so a fold that crosses the pane is passed as the part of the
    /// fold inside the pane, shifted by the pane's origin. Pass only regions that are active now;
    /// an empty array (the default) leaves the layout untouched.
    ///
    /// Only vertical dividers (narrower than half the pane and at least as tall as wide) move
    /// anything: the two center buttons on each side of the fold stay on their own side of it, and
    /// the compact layout widens the gap between its two halves. The side columns never move.
    @Entry var controllerKeepClearRegions: [CGRect] = []
}
