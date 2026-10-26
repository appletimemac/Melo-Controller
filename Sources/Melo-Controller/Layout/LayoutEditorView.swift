//
//  LayoutEditorView.swift
//  Melo-Controller
//
//  Created by Stossy11 on 26/1/2026.
//

import SwiftUI

class JoystickDPadUIHandler: ObservableObject {
    @Published var gameId: String?

    var joystickDpad: Bool {
        get {
            UserDefaults.standard.bool(forKey: "joystickDpad-\(gameId ?? "global")")
        }
        set {
            UserDefaults.standard.set(newValue, forKey: "joystickDpad-\(gameId ?? "global")")
            objectWillChange.send()
        }
    }
}

struct LayoutEditorView: View {
    @AppStorage("On-ScreenControllerScale") private var defaultControllerScale: Double = 1.0
    @Environment(\.resolvedControllerScale) private var resolvedControllerScale
    @AppStorage("buttonSlide") private var buttonSlide = true
    @StateObject var joystickDpad = JoystickDPadUIHandler()
    
    @Binding var hideDpad: Bool
    @Binding var hideABXY: Bool
    @Binding var isEditing: Bool
    @Binding var showEditControls: Bool
    @Binding var layout: LayoutConfig
    var variant: ControllerLayoutVariant
    
    @Binding var selectedButton: String?
    @Binding var selectedJoystick: String?
    
    @State private var showingLayoutOptions = false
    @State private var showingResetAlert = false
    
    @Environment(\.dismiss) var dismiss
    
    var gameId: String?
    var gameName: String?
    /// Called after Reset or Delete removed this variant's saved file.
    var onReset: () -> Void = {}
    
    private var gameTitle: String? {
        guard let gameId = gameId else { return nil }
        return gameName ?? gameId
    }
    
    private var selectionKey: String {
        "\(selectedButton ?? "-")|\(selectedJoystick ?? "-")"
    }
    
    private func syncDpadHandler() {
        joystickDpad.gameId = gameId
    }
    
    private func saveLayout() {
        LayoutManager.shared.save(layout, for: gameId, variant: variant)
    }
    
    private func clearSelection() {
        selectedButton = nil
        selectedJoystick = nil
    }
    
    var body: some View {
        // The editor arranges itself from the space it has, not from the device it runs on.
        GeometryReader { proxy in
            let isWide = proxy.size.width >= 520
            GlassEffectContainer(spacing: 12) {
                VStack(spacing: 10) {
                    toolbar(isWide: isWide)
                    
                    if isWide {
                        HStack(alignment: .top, spacing: 10) {
                            scrollingInspector
                                .frame(maxWidth: 360, alignment: .leading)
                            
                            Spacer(minLength: 0)
                            
                            VStack(alignment: .trailing, spacing: 8) {
                                badges
                            }
                        }
                    } else {
                        HStack(spacing: 8) {
                            badges
                            Spacer(minLength: 0)
                        }
                        
                        scrollingInspector
                    }
                    
                    Spacer(minLength: 0)
                }
                .padding(12)
            }
        }
        .animation(.spring(response: 0.34, dampingFraction: 0.86), value: selectionKey)
        .onAppear {
            syncDpadHandler()
        }
        .onChange(of: gameId) {
            syncDpadHandler()
        }
        .sheet(isPresented: $showingLayoutOptions) {
            LayoutOptionsView(gameId: gameId, gameName: gameName, layout: $layout, variant: variant, onReset: onReset)
        }
        .alert("Reset This Layout?", isPresented: $showingResetAlert) {
            Button("Cancel", role: .cancel) {}
            Button("Reset", role: .destructive) {
                layout = LayoutConfig()
                LayoutManager.shared.reset(for: gameId, variant: variant)
                onReset()
                clearSelection()
            }
        } message: {
            Text("Every button and stick goes back to its default position, size and options.")
        }
    }
    
    
    /// Titles and symbols when they fit, symbols alone when they do not, however large the text is.
    @ViewBuilder
    private func toolbar(isWide: Bool) -> some View {
        if isWide {
            ViewThatFits(in: .horizontal) {
                toolbarRow(showTitles: true, showDoneTitle: true)
                toolbarRow(showTitles: false, showDoneTitle: true)
                toolbarRow(showTitles: false, showDoneTitle: false)
            }
        } else {
            ViewThatFits(in: .horizontal) {
                toolbarRow(showTitles: false, showDoneTitle: true)
                toolbarRow(showTitles: false, showDoneTitle: false)
            }
        }
    }
    
    private func toolbarRow(showTitles: Bool, showDoneTitle: Bool) -> some View {
        HStack(spacing: 8) {
            EditorToolbarButton(title: "Hide", systemImage: "eye.slash", showTitle: showTitles) {
                withAnimation(.easeInOut(duration: 0.3)) {
                    showEditControls = false
                }
            }
            
            EditorToolbarButton(title: "Options", systemImage: "slider.horizontal.3", showTitle: showTitles) {
                showingLayoutOptions = true
            }
            
            EditorToolbarButton(title: "Reset All", systemImage: "arrow.counterclockwise", tint: .orange, showTitle: showTitles) {
                showingResetAlert = true
            }
            
            Spacer(minLength: 4)
            
            Button {
                saveLayout()
                clearSelection()
                isEditing = false
                dismiss()
            } label: {
                Label("Done", systemImage: "checkmark")
                    .labelStyle(EditorToolbarLabelStyle(showTitle: showDoneTitle))
                    .font(.footnote.weight(.semibold))
                    .lineLimit(1)
            }
            .buttonStyle(.glassProminent)
        }
    }
    
    @ViewBuilder
    private var badges: some View {
        if let gameTitle = gameTitle {
            EditorBadge(title: gameTitle, systemImage: "gamecontroller.fill")
        }
        
        EditorBadge(title: variant.title, systemImage: variant.systemImage)
    }
    
    
    /// The inspector at its natural size, or scrolling when large text makes it taller than the room it has.
    private var scrollingInspector: some View {
        ViewThatFits(in: .vertical) {
            inspector
            ScrollView { inspector }
                .scrollBounceBehavior(.basedOnSize)
        }
    }
    
    @ViewBuilder
    private var inspector: some View {
        if let selectedButton = selectedButton {
            buttonControls(for: selectedButton)
                .transition(.move(edge: .leading).combined(with: .opacity))
        } else if let selectedJoystick = selectedJoystick {
            joystickControls(for: selectedJoystick)
                .transition(.move(edge: .leading).combined(with: .opacity))
        } else {
            globalControls
                .transition(.opacity)
        }
    }
    
    private var globalControls: some View {
        EditorCard {
            EditorCardHeader(
                title: "Whole Controller",
                subtitle: "Tap a button or stick to edit it, drag it to move it."
            )
            
            // The size belongs to the variant showing, in every game, like the in-game size controls.
            EditorSliderRow(
                title: "Controller Size",
                value: Binding(
                    get: { CGFloat(resolvedControllerScale ?? defaultControllerScale) },
                    set: { UserDefaults.standard.set(Double($0), forKey: variant.scaleKey) }
                ),
                range: ControllerPlacement.scaleRange
            )
            
            EditorToggleRow(
                title: "Roll Between Buttons",
                subtitle: "Slide a finger straight from one button to the next.",
                isOn: $buttonSlide
            )
        }
    }
    
    
    private func buttonControls(for buttonId: String) -> some View {
        EditorCard {
            EditorCardHeader(
                title: LayoutEditorNaming.displayName(for: buttonId),
                subtitle: "Button"
            ) {
                EditorResetButton {
                    layout.buttons[buttonId] = nil
                    selectedButton = nil
                }
            }
            
            EditorSliderRow(
                title: "Size",
                value: Binding(
                    get: { layout.buttons[buttonId]?.scale ?? 1.0 },
                    set: { layout.buttons[buttonId, default: ButtonLayout()].scale = $0 }
                )
            )
            
            EditorToggleRow(
                title: "Hide Button",
                isOn: Binding(
                    get: { layout.buttons[buttonId]?.hidden ?? false },
                    set: { layout.buttons[buttonId, default: ButtonLayout()].hidden = $0 }
                )
            )
            
            EditorToggleRow(
                title: "Toggle Instead of Hold",
                subtitle: "Stays held down until it's tapped again.",
                isOn: Binding(
                    get: { layout.buttons[buttonId]?.toggle ?? false },
                    set: { layout.buttons[buttonId, default: ButtonLayout()].toggle = $0 }
                )
            )
            
            if buttonId.lowercased().contains("dpad") {
                EditorToggleRow(
                    title: "D-Pad Acts Like a Stick",
                    isOn: Binding(
                        get: { joystickDpad.joystickDpad },
                        set: { joystickDpad.joystickDpad = $0 }
                    )
                )
            }
        }
    }
    
    
    private func joystickControls(for joystickId: String) -> some View {
        EditorCard {
            EditorCardHeader(
                title: LayoutEditorNaming.displayName(for: joystickId),
                subtitle: "Stick"
            ) {
                EditorResetButton {
                    layout.joysticks[joystickId] = nil
                    selectedJoystick = nil
                }
            }
            
            EditorSliderRow(
                title: "Size",
                value: Binding(
                    get: { layout.joysticks[joystickId]?.scale ?? 1.0 },
                    set: { layout.joysticks[joystickId, default: JoystickLayout()].scale = $0 }
                )
            )
            
            EditorToggleRow(
                title: "Hide Stick",
                isOn: Binding(
                    get: { layout.joysticks[joystickId]?.hidden ?? false },
                    set: { layout.joysticks[joystickId, default: JoystickLayout()].hidden = $0 }
                )
            )
            
            EditorToggleRow(
                title: "Hide Buttons Underneath",
                subtitle: "Fades the overlapping D-Pad or ABXY buttons while the stick is in use.",
                isOn: Binding(
                    get: { layout.joysticks[joystickId]?.hide ?? true },
                    set: { layout.joysticks[joystickId, default: JoystickLayout()].hide = $0 }
                )
            )
            
            EditorToggleRow(
                title: "Always Show Background",
                isOn: Binding(
                    get: { layout.joysticks[joystickId]?.background ?? false },
                    set: { layout.joysticks[joystickId, default: JoystickLayout()].background = $0 }
                )
            )
        }
    }
}

enum LayoutEditorNaming {
    static func displayName(for id: String) -> String {
        if id.count == 1 { return id.uppercased() }
        
        var words: [String] = []
        var current = ""
        for character in id {
            if character.isUppercase && !current.isEmpty {
                words.append(current)
                current = String(character)
            } else {
                current.append(character)
            }
        }
        if !current.isEmpty { words.append(current) }
        
        return words
            .map { word -> String in
                switch word.lowercased() {
                case "dpad", "d": return "D-Pad"
                case "pad": return "Pad"
                case "abxy": return "ABXY"
                default: return word.prefix(1).uppercased() + word.dropFirst()
                }
            }
            .joined(separator: " ")
            .replacingOccurrences(of: "D Pad", with: "D-Pad")
    }
}

struct EditorCard<Content: View>: View {
    @ViewBuilder var content: Content
    
    var body: some View {
        VStack(alignment: .leading, spacing: 14) {
            content
        }
        .padding(16)
        .glassEffect(.regular, in: RoundedRectangle(cornerRadius: 20, style: .continuous))
    }
}

struct EditorCardHeader<Accessory: View>: View {
    let title: String
    var subtitle: String?
    @ViewBuilder var accessory: Accessory
    
    var body: some View {
        HStack(alignment: .firstTextBaseline, spacing: 8) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
            
            Spacer(minLength: 4)
            
            accessory
        }
    }
}

extension EditorCardHeader where Accessory == EmptyView {
    init(title: String, subtitle: String? = nil) {
        self.init(title: title, subtitle: subtitle) { EmptyView() }
    }
}

struct EditorResetButton: View {
    let action: () -> Void
    
    var body: some View {
        Button("Reset", action: action)
            .font(.caption.weight(.semibold))
            .foregroundStyle(.orange)
            .buttonStyle(.plain)
    }
}

/// A toolbar button of the editor: a glass button with a title and a symbol. Narrow layouts show the
/// symbol alone; the title stays as the accessibility label.
struct EditorToolbarButton: View {
    let title: LocalizedStringKey
    let systemImage: String
    var tint: Color?
    var showTitle: Bool = true
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            Label(title, systemImage: systemImage)
                .labelStyle(EditorToolbarLabelStyle(showTitle: showTitle))
                .font(.footnote.weight(.semibold))
                .lineLimit(1)
        }
        .buttonStyle(.glass)
        .foregroundStyle(tint ?? .primary)
    }
}

private struct EditorToolbarLabelStyle: LabelStyle {
    let showTitle: Bool
    
    func makeBody(configuration: Configuration) -> some View {
        if showTitle {
            Label(configuration)
        } else {
            Label(configuration)
                .labelStyle(.iconOnly)
        }
    }
}

/// A small read-only glass capsule naming the game or the layout being edited.
struct EditorBadge: View {
    let title: LocalizedStringKey
    let systemImage: String
    
    init(title: LocalizedStringKey, systemImage: String) {
        self.title = title
        self.systemImage = systemImage
    }
    
    init(title: String, systemImage: String) {
        self.title = LocalizedStringKey(title)
        self.systemImage = systemImage
    }
    
    var body: some View {
        Label {
            Text(title)
                .lineLimit(1)
                .truncationMode(.middle)
        } icon: {
            Image(systemName: systemImage)
        }
        .font(.caption)
        .foregroundStyle(.secondary)
        .padding(.horizontal, 14)
        .padding(.vertical, 10)
        .glassEffect(.regular, in: Capsule(style: .continuous))
        .frame(maxWidth: 220)
    }
}

struct EditorSliderRow: View {
    let title: String
    @Binding var value: CGFloat
    var range: ClosedRange<CGFloat> = 0.5...2.0
    var step: CGFloat = 0.1
    
    private func nudge(_ amount: CGFloat) {
        let next = (value + amount).rounded(toNearest: step)
        value = min(range.upperBound, max(range.lowerBound, next))
        Haptics.shared.play(.light)
    }
    
    var body: some View {
        VStack(spacing: 4) {
            HStack {
                Text(title)
                    .font(.caption.weight(.medium))
                    .foregroundStyle(.secondary)
                Spacer()
                Text(String(format: "%.1f×", value))
                    .font(.caption.weight(.semibold).monospacedDigit())
                    .foregroundStyle(.secondary)
            }
            
            HStack(spacing: 12) {
                EditorStepperButton(icon: "minus", label: "Decrease") { nudge(-step) }
                
                Slider(value: $value, in: range, step: step) { Text(title) }
                
                EditorStepperButton(icon: "plus", label: "Increase") { nudge(step) }
            }
        }
    }
}

struct EditorStepperButton: View {
    let icon: String
    let label: LocalizedStringKey
    let action: () -> Void
    @ScaledMetric(relativeTo: .footnote) private var tapSize: CGFloat = 32
    
    var body: some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.footnote.weight(.bold))
                .foregroundStyle(.secondary)
                .frame(minWidth: tapSize, minHeight: tapSize)
                .contentShape(Rectangle())
        }
        .buttonStyle(.plain)
        .accessibilityLabel(label)
    }
}

struct EditorToggleRow: View {
    let title: String
    var subtitle: String?
    @Binding var isOn: Bool
    
    var body: some View {
        Toggle(isOn: $isOn) {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.caption.weight(.medium))
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                        .fixedSize(horizontal: false, vertical: true)
                }
            }
        }
        .toggleStyle(.switch)
    }
}

private extension CGFloat {
    func rounded(toNearest step: CGFloat) -> CGFloat {
        guard step > 0 else { return self }
        
        return (self / step).rounded() * step
    }
}

struct EditorSelectionRing: ViewModifier {
    let isSelected: Bool
    var isCircular: Bool = true
    var tint: Color = .blue
    
    func body(content: Content) -> some View {
        content
            .overlay {
                Group {
                    if isCircular {
                        Circle()
                            .strokeBorder(tint, lineWidth: 2.5)
                    } else {
                        RoundedRectangle(cornerRadius: 12, style: .continuous)
                            .strokeBorder(tint, lineWidth: 2.5)
                    }
                }
                .padding(-7)
                .opacity(isSelected ? 1 : 0)
                .animation(.easeOut(duration: 0.16), value: isSelected)
            }
    }
}

extension View {
    func editorSelectionRing(isSelected: Bool, isCircular: Bool = true, tint: Color = .blue) -> some View {
        modifier(EditorSelectionRing(isSelected: isSelected, isCircular: isCircular, tint: tint))
    }
}
