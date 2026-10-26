//
//  ControllerSurface.swift
//  Melo-Controller
//

import SwiftUI

/// The buttons and sticks of the controller in one layout variant, with the layout they read and edit.
struct ControllerSurface: View {
    let variant: ControllerLayoutVariant
    let clearance: FoldClearance
    var controller: any Controller
    var gameId: String?
    var isEditing: Bool
    @Binding var layout: LayoutConfig
    @Binding var hideDpad: Bool
    @Binding var hideABXY: Bool
    @Binding var selectedButton: String?
    @Binding var selectedJoystick: String?
    /// The frame the built-in layouts' controls take in the pane, before any vertical offset; nil
    /// for a custom layout, which is never measured.
    @Binding var controlsFrame: CGRect?
    var customControllerLayout: ((@escaping SubView, @escaping JoystickSubView, Bool) -> AnyView)?

    @AppStorage("On-ScreenControllerScale") private var controllerScale: Double = 1.0
    @AppStorage("stickButton") private var stickButton = false
    private var glass = ControllerGlassPreference()

    init(
        variant: ControllerLayoutVariant,
        clearance: FoldClearance,
        controller: any Controller,
        gameId: String?,
        isEditing: Bool,
        layout: Binding<LayoutConfig>,
        hideDpad: Binding<Bool>,
        hideABXY: Binding<Bool>,
        selectedButton: Binding<String?>,
        selectedJoystick: Binding<String?>,
        controlsFrame: Binding<CGRect?>,
        customControllerLayout: ((@escaping SubView, @escaping JoystickSubView, Bool) -> AnyView)?
    ) {
        self.variant = variant
        self.clearance = clearance
        self.controller = controller
        self.gameId = gameId
        self.isEditing = isEditing
        self._layout = layout
        self._hideDpad = hideDpad
        self._hideABXY = hideABXY
        self._selectedButton = selectedButton
        self._selectedJoystick = selectedJoystick
        self._controlsFrame = controlsFrame
        self.customControllerLayout = customControllerLayout
    }

    var body: some View {
        Group {
            if let customControllerLayout {
                customControllerLayout(editableButton, editableJoystick, variant == .portrait)
                    .onAppear { controlsFrame = nil }
            } else if variant == .portrait {
                portraitLayout
            } else {
                landscapeLayout
            }
        }
        .padding()
        .coordinateSpace(.named(Self.paneSpace))
    }

    private static let paneSpace = "ControllerSurfacePane"

    private func measuringControls(_ controls: some View) -> some View {
        controls.onGeometryChange(for: CGRect.self) { $0.frame(in: .named(Self.paneSpace)) } action: {
            controlsFrame = $0
        }
    }

    private var portraitLayout: some View {
        let scale = CGFloat(controllerScale)
        let columnWidth = max(ControllerLayoutVariant.halfWidth, ControllerLayoutVariant.halfWidth * scale, 145 * scale)
        let padding: CGFloat = 32
        let columnGap = clearance.centeredGap(
            base: 30,
            limit: clearance.paneSize.width - padding - 2 * columnWidth
        )
        let bottomHalfWidth = stickButton ? 80 * scale + 32 : 35 * scale
        let bottomGap = clearance.centeredGap(
            base: 60,
            extraMargin: 0.125 * 35 * scale,
            limit: clearance.paneSize.width - padding - 2 * bottomHalfWidth
        )
        return VStack {
            Spacer()
            measuringControls(VStack(spacing: 20) {
                HStack(spacing: columnGap) {
                    VStack(spacing: 15) {
                        shoulderButtonsLeft
                        ZStack {
                            editableJoystick(id: "leftJoystick", showBackground: $hideDpad)

                            if layout.joysticks["leftJoystick"]?.hide ?? true {
                                dpadView
                                    .opacity(hideDpad ? 0 : 1)
                                    .allowsHitTesting(!hideDpad)
                                    .animation(.easeInOut(duration: 0.2), value: hideDpad)
                            } else {
                                dpadView
                            }
                        }
                    }

                    VStack(spacing: 15) {
                        shoulderButtonsRight
                        ZStack {
                            editableJoystick(id: "rightJoystick", iscool: true, showBackground: $hideABXY)
                            if layout.joysticks["rightJoystick"]?.hide ?? true {
                                abxyView
                                    .opacity(hideABXY ? 0 : 1)
                                    .allowsHitTesting(!hideABXY)
                                    .animation(.easeInOut(duration: 0.2), value: hideABXY)
                            } else {
                                abxyView
                            }
                        }
                    }
                }

                if stickButton {
                    HStack(spacing: bottomGap) {
                        HStack {
                            editableButton(.leftStick).padding()
                            editableButton(.back)
                        }
                        HStack {
                            editableButton(.start)
                            editableButton(.rightStick).padding()
                        }
                    }
                } else {
                    HStack(spacing: bottomGap) {
                        HStack {
                            editableButton(.back)
                        }
                        HStack {
                            editableButton(.start)
                        }
                    }
                }
            })
        }
    }

    private var landscapeLayout: some View {
        VStack {
            Spacer()
            measuringControls(HStack {
                VStack(spacing: 20) {
                    shoulderButtonsLeft
                    ZStack {
                        editableJoystick(id: "leftJoystick", showBackground: $hideDpad)

                        if layout.joysticks["leftJoystick"]?.hide ?? true {
                            dpadView
                                .opacity(hideDpad ? 0 : 1)
                                .allowsHitTesting(!hideDpad)
                                .animation(.easeInOut(duration: 0.2), value: hideDpad)
                        } else {
                            dpadView
                        }
                    }
                }

                Spacer()
                centerButtons
                Spacer()

                VStack(spacing: 20) {
                    shoulderButtonsRight
                    ZStack {
                        editableJoystick(id: "rightJoystick", iscool: true, showBackground: $hideABXY)
                        if layout.joysticks["rightJoystick"]?.hide ?? true {
                            abxyView
                                .opacity(hideABXY ? 0 : 1)
                                .allowsHitTesting(!hideABXY)
                                .animation(.easeInOut(duration: 0.2), value: hideABXY)
                        } else {
                            abxyView
                        }
                    }
                }
            })
        }
    }

    private var centerButtons: some View {
        // The buttons are drawn 1.25 times their frame, so the drawing reaches past the frame by this much.
        let overhang = 0.125 * 35 * CGFloat(controllerScale)
        return glassCluster {
            CenterClusterLayout(clearance: clearance.span(extraMargin: overhang)) {
                centerLeadingButtons
                centerTrailingButtons
            }
        }
        .padding(.bottom, 20)
    }

    // Minus (and L3) belong to the left Joy-Con, Plus (and R3) to the right one.
    private var centerLeadingButtons: some View {
        VStack(alignment: .leading) {
            if stickButton {
                HStack { editableButton(.leftStick).padding() }
                    .padding(.top, 30)
            }
            HStack { editableButton(.back) }
        }
    }

    private var centerTrailingButtons: some View {
        VStack(alignment: .trailing) {
            if stickButton {
                HStack { editableButton(.rightStick).padding() }
                    .padding(.top, 30)
            }
            HStack { editableButton(.start) }
        }
    }

    // MARK: - Button Groups

    private var shoulderButtonsLeft: some View {
        glassCluster {
            HStack(spacing: 20) {
                editableButton(.leftTrigger)
                editableButton(.leftShoulder)
            }
        }
        .frame(width: 160 * CGFloat(controllerScale), height: 20 * CGFloat(controllerScale))
    }

    private var shoulderButtonsRight: some View {
        glassCluster {
            HStack(spacing: 20) {
                editableButton(.rightShoulder)
                editableButton(.rightTrigger)
            }
        }
        .frame(width: 160 * CGFloat(controllerScale), height: 20 * CGFloat(controllerScale))
    }

    private var dpadView: some View {
        glassCluster {
            VStack(spacing: 7) {
                editableButton(.dPadUp)
                HStack(spacing: 22) {
                    editableButton(.dPadLeft)
                    Spacer(minLength: 22)
                    editableButton(.dPadRight)
                }
                editableButton(.dPadDown)
            }
        }
        .frame(width: 145 * CGFloat(controllerScale), height: 145 * CGFloat(controllerScale))
    }

    private var abxyView: some View {
        glassCluster {
            VStack(spacing: 7) {
                editableButton(.X)
                HStack(spacing: 22) {
                    editableButton(.Y)
                    Spacer(minLength: 22)
                    editableButton(.A)
                }
                editableButton(.B)
            }
        }
        .frame(width: 145 * CGFloat(controllerScale), height: 145 * CGFloat(controllerScale))
    }

    // MARK: - Helper Methods

    /// Glass shapes that sit next to each other render together in one container, so they share a sampling
    /// pass and look consistent. Spacing 0 keeps neighbouring buttons from merging into one blob.
    @ViewBuilder
    private func glassCluster<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        if glass.isActive {
            GlassEffectContainer(spacing: 0) { content() }
        } else {
            content()
        }
    }

    private func editableButton(_ button: VirtualControllerButton) -> AnyView {
        .init(
            EditableButtonView(
                button: button,
                controller: controller,
                layout: $layout,
                gameId: gameId,
                isEditing: isEditing,
                selectedButton: $selectedButton,
                selectedJoystick: $selectedJoystick
            )
        )
    }

    private func editableJoystick(
        id: String,
        iscool: Bool = false,
        showBackground: Binding<Bool>,
    ) -> AnyView {
        .init(
            EditableJoystickView(
                id: id,
                iscool: iscool,
                controller: controller,
                showBackground: showBackground,
                layout: $layout,
                isEditing: isEditing,
                selectedJoystick: $selectedJoystick,
                selectedButton: $selectedButton,
            )
        )
    }
}
