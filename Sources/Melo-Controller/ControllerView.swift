//
//  ControllerView.swift
//  Melo-Controller
//
//  Created by Stossy11 on 16/7/2024.
//

import SwiftUI
import GameController
import CoreMotion

/// A closure type used to build an individual button in a custom controller layout.
/// Receives a ``VirtualControllerButton`` and returns a type-erased view.
public typealias SubView = (VirtualControllerButton) -> AnyView

/// A closure type used to build a joystick in a custom controller layout.
///
/// Parameters:
/// - `String`: The joystick ID (e.g. `"leftJoystick"`, `"rightJoystick"`)
/// - `Bool`: `true` if this is the right stick (`iscool`)
/// - `Binding<Bool>`: Controls whether the overlapping D-pad / ABXY overlay is hidden
public typealias JoystickSubView = (String, Bool, Binding<Bool>) -> AnyView

/// A full on-screen nintendo-style game controller  as a SwiftUI view.
///
/// `ControllerView` handles layout persistence and edit mode. By default it renders a compact (portrait)
/// or a spread (landscape) layout, chosen from the space the view itself is given rather than from the
/// device or the window, so it works in any pane, on any display, in any pose.
/// Pass a `customControllerLayout` closure to provide your own arrangement of buttons and sticks.
///
/// - Controls draw as Liquid Glass unless the `On-ScreenControllerGlass` user default is `false` or
///   Reduce Transparency is on. `On-ScreenControllerScale` scales every control.
/// - Rectangles in ``EnvironmentValues/controllerKeepClearRegions`` (such as a fold) are kept clear of
///   the center buttons.
/// - Layouts are stored per game and per variant, and the editor edits the variant that is showing.
///
/// **Basic usage (default layout):**
/// ```swift
/// ControllerView(controller: myController, isEditing: false)
/// ```
///
/// **Custom layout:**
/// ```swift
/// ControllerView(controller: myController, isEditing: false) { button, joystick, isPortrait in
///     HStack {
///         joystick("leftJoystick", false, $hideDpad)
///         Spacer()
///         joystick("rightJoystick", true, $hideABXY)
///     }
/// }
/// ```
public struct ControllerView: View {
    var gameId: String?
    var gameName: String?
    var controller: any Controller
    @AppStorage("On-ScreenControllerScale") private var controllerScale: Double = 1.0
    @AppStorage("stickButton") private var stickButton = false
    @Environment(\.controllerKeepClearRegions) private var keepClearRegions
    @State private var hideDpad = false
    @State private var hideABXY = false
    @State private var selectedButton: String?
    @State private var selectedJoystick: String?
    @State private var showEditControls = true
    @State var isEditing: Bool = false
    private var isEditingInput: Bool

    /// An optional closure that replaces the built-in portrait/landscape layouts.
    ///
    /// The closure receives:
    /// - A ``SubView`` factory:  call it with any ``VirtualControllerButton`` to get a fully wired, editable button view.
    /// - A ``JoystickSubView`` factory: call it with an ID, `iscool`, and a `showBackground` binding to get a wired joystick.
    /// - A `Bool` that is `true` while the compact (portrait) arrangement is showing, decided from the
    ///   size of the view itself.
    ///
    /// Set to `nil` (the default) to use the automatic portrait/landscape layout.
    @State var customControllerLayout: ((@escaping SubView, @escaping JoystickSubView, Bool) -> AnyView)? = nil

    /// Creates a `ControllerView` with a custom button/joystick layout.
    ///
    /// - Parameters:
    ///   - controller: The ``Controller`` object that receives all button and stick input.
    ///   - isEditing: Pass `true` to enter edit mode, where buttons and sticks can be
    ///     repositioned and scaled. Pass `false` for normal play.
    ///   - gameId: An optional identifier used to load and save a per-game layout.
    ///     Pass `nil` to use the global layout.
    ///   - gameName: An optional display name for the game, shown in the layout editor
    ///     instead of `gameId`. The layout is still saved under `gameId`.
    ///   - customControllerLayout: A `@ViewBuilder` closure that composes your own
    ///     controller UI using the provided ``SubView`` and ``JoystickSubView`` factories.
    ///     The `Bool` argument is `true` while the compact (portrait) arrangement is showing,
    ///     which you can use to switch between layouts.
    public init<V: View>(
        controller: any Controller,
        isEditing: Bool,
        gameId: String? = nil,
        gameName: String? = nil,
        @ViewBuilder customControllerLayout: @escaping (@escaping SubView, @escaping JoystickSubView, Bool) -> V
    ) {
        self.isEditingInput = isEditing
        self._isEditing = State(initialValue: isEditing)
        self.gameId = gameId
        self.gameName = gameName
        self.controller = controller
        self._customControllerLayout = State(initialValue: { s1, s2, s3 in AnyView(customControllerLayout(s1, s2, s3)) })
    }
    
    public init(
        controller: any Controller,
        isEditing: Bool,
        gameId: String? = nil,
        gameName: String? = nil
    ) {
        self.isEditingInput = isEditing
        self._isEditing = State(initialValue: isEditing)
        self.gameId = gameId
        self.gameName = gameName
        self.controller = controller
    }


    /// The stored layout of each variant. Both are kept so a variant switch (a rotation, a fold) applies
    /// the right offsets in the same frame.
    @State private var layouts = VariantLayouts()
    @State private var savedLayouts = VariantLayouts()

    public var body: some View {
        GeometryReader { proxy in
            let clearance = FoldClearance(paneSize: proxy.size, regions: keepClearRegions)
            let variant = ControllerLayoutVariant(
                paneSize: proxy.size,
                controllerScale: CGFloat(controllerScale),
                stickButtons: stickButton,
                foldWidth: clearance.centerFoldWidth
            )
            let layout = layoutBinding(for: variant)
            ZStack {
                ControllerSurface(
                    variant: variant,
                    clearance: clearance,
                    controller: controller,
                    gameId: gameId,
                    isEditing: isEditing,
                    layout: layout,
                    hideDpad: $hideDpad,
                    hideABXY: $hideABXY,
                    selectedButton: $selectedButton,
                    selectedJoystick: $selectedJoystick,
                    customControllerLayout: customControllerLayout
                )
                .onChange(of: isEditingInput) { _, newValue in isEditing = newValue }
                .onAppear { loadLayouts() }

                // Edit Controls
                if isEditing {
                    if showEditControls {
                        LayoutEditorView(
                            hideDpad: $hideDpad,
                            hideABXY: $hideABXY,
                            isEditing: $isEditing,
                            showEditControls: $showEditControls,
                            layout: layout,
                            variant: variant,
                            selectedButton: $selectedButton,
                            selectedJoystick: $selectedJoystick,
                            gameId: gameId,
                            gameName: gameName
                        )
                        .zIndex(1)
                    } else {
                        VStack {
                            HStack {
                                Button(action: {
                                    withAnimation(.easeInOut(duration: 0.3)) {
                                        showEditControls = true
                                    }
                                }) {
                                    Label("Show Editor Controls", systemImage: "eye")
                                        .labelStyle(.iconOnly)
                                }
                                .buttonStyle(.glass)
                                .buttonBorderShape(.circle)
                                .padding(12)

                                Spacer()
                            }

                            Spacer()
                        }
                    }
                }
            }
            .frame(width: proxy.size.width, height: proxy.size.height)
            .onChange(of: variant) { oldVariant, _ in
                // Rotating or folding in the editor must not lose what was changed in the variant being left.
                if isEditing { saveIfEdited(oldVariant) }
            }
        }
    }

    private func layoutBinding(for variant: ControllerLayoutVariant) -> Binding<LayoutConfig> {
        Binding(
            get: { layouts[variant] },
            set: { layouts[variant] = $0 }
        )
    }

    private func loadLayouts() {
        LayoutManager.shared.migrateLegacyLayout(for: gameId)

        var loaded = VariantLayouts()
        for variant in ControllerLayoutVariant.allCases {
            loaded[variant] = LayoutManager.shared.load(for: gameId, variant: variant)
        }
        layouts = loaded
        savedLayouts = loaded
    }

    private func saveIfEdited(_ variant: ControllerLayoutVariant) {
        guard layouts[variant] != savedLayouts[variant] else { return }
        LayoutManager.shared.save(layouts[variant], for: gameId, variant: variant)
        savedLayouts[variant] = layouts[variant]
    }
}
