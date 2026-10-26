//
//  ButtonAccessibility.swift
//  Melo-Controller
//

import Foundation

extension VirtualControllerButton {
    /// What VoiceOver calls this control. It is a name only: a hint would speak during play.
    var accessibilityName: String {
        switch id {
        case "A": return String(localized: "A button")
        case "B": return String(localized: "B button")
        case "X": return String(localized: "X button")
        case "Y": return String(localized: "Y button")
        case "back": return String(localized: "Minus button")
        case "start": return String(localized: "Plus button")
        case "guide": return String(localized: "Menu")
        case "leftStick": return String(localized: "Left stick button")
        case "rightStick": return String(localized: "Right stick button")
        case "leftShoulder": return String(localized: "L button")
        case "rightShoulder": return String(localized: "R button")
        case "leftTrigger": return String(localized: "ZL button")
        case "rightTrigger": return String(localized: "ZR button")
        case "dPadUp": return String(localized: "D-pad up")
        case "dPadDown": return String(localized: "D-pad down")
        case "dPadLeft": return String(localized: "D-pad left")
        case "dPadRight": return String(localized: "D-pad right")
        default: return LayoutEditorNaming.displayName(for: id)
        }
    }
}

enum StickAccessibility {
    static func name(right: Bool) -> String {
        right
            ? String(localized: "Right stick")
            : String(localized: "Left stick")
    }
}
