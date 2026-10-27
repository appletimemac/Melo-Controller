//
//  CopyLayoutView.swift
//  Melo-Controller
//
//  Created by Stossy11 on 26/1/2026.
//

import SwiftUI

struct CopyLayoutView: View {
    let targetGameId: String?
    @Binding var layout: LayoutConfig
    var variant: ControllerLayoutVariant
    @Environment(\.dismiss) private var dismiss
    @State private var availableLayouts: [String] = []
    
    var body: some View {
        NavigationStack {
            List {
                Section("Available Layouts") {
                    Button(action: {
                        copyLayout(from: nil)
                    }) {
                        HStack {
                            Label("Default Layout", systemImage: "gear")
                                .foregroundStyle(.primary)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                                .accessibilityHidden(true)
                        }
                    }
                    
                    ForEach(availableLayouts, id: \.self) { gameId in
                        if gameId != targetGameId {
                            Button(action: {
                                copyLayout(from: gameId)
                            }) {
                                HStack {
                                    Label(gameId, systemImage: "gamecontroller.fill")
                                        .foregroundStyle(.primary)
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                        .accessibilityHidden(true)
                                }
                            }
                        }
                    }
                }
            }
            .navigationTitle("Copy Layout")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel", systemImage: "xmark", role: .cancel) {
                        dismiss()
                    }
                }
            }
        }
        .onAppear {
            loadAvailableLayouts()
        }
    }
    
    private func loadAvailableLayouts() {
        availableLayouts = LayoutManager.shared.getAllGameLayouts()
    }
    
    private func copyLayout(from sourceGameId: String?) {
        let sourceLayout = LayoutManager.shared.load(for: sourceGameId, variant: variant)
        layout = sourceLayout
        LayoutManager.shared.save(layout, for: targetGameId, variant: variant)
        dismiss()
    }
}

struct EditableButtonView: View {
    let button: VirtualControllerButton
    var controller: any Controller
    @Binding var layout: LayoutConfig
    var gameId: String?
    var isEditing: Bool
    @Binding var selectedButton: String?
    @Binding var selectedJoystick: String?
    @GestureState private var dragOffset = CGSize.zero

    var body: some View {
        Group {
            if isEditing {
                ButtonView(controller: controller, disabled: true, button: button)
                    .opacity(layout.buttons[button.id]?.hidden ?? false ? 0.35 : 1)
                    .accessibilityAddTraits(selectedButton == button.id ? [.isButton, .isSelected] : .isButton)
                    .editorSelectionRing(isSelected: selectedButton == button.id, isCircular: !button.isTrigger)
                    // The selection bump stays out of the reported frame, or selecting a control
                    // would move a controller sitting at its offset limit.
                    .scaleEffect(selectedButton == button.id ? 1.06 : 1.0)
                    .reportsControlFrame(
                        !(layout.buttons[button.id]?.hidden ?? false),
                        isDragging: dragOffset != .zero
                    )
                    .scaleEffect(layout.buttons[button.id]?.scale ?? 1.0)
                    .offset(
                        x: (layout.buttons[button.id]?.offset.width ?? 0) + dragOffset.width,
                        y: (layout.buttons[button.id]?.offset.height ?? 0) + dragOffset.height
                    )
                    .onTapGesture {
                        selectedButton = selectedButton == button.id ? nil : button.id
                        selectedJoystick = nil
                        Haptics.shared.play(.light)
                    }
                    .gesture(
                        DragGesture()
                            .updating($dragOffset) { value, state, _ in
                                state = value.translation
                                selectedButton = button.id
                                selectedJoystick = nil
                            }
                            .onEnded { value in
                                layout.buttons[button.id, default: ButtonLayout()].offset.width += value.translation.width
                                layout.buttons[button.id, default: ButtonLayout()].offset.height += value.translation.height
                            }
                    )
            } else {
                if layout.buttons[button.id, default: ButtonLayout()].hidden {
                    ButtonView(controller: controller, button: button, layout: $layout, gameId: gameId)
                        .scaleEffect(layout.buttons[button.id]?.scale ?? 1.0)
                        .offset(layout.buttons[button.id]?.offset ?? .zero)
                        .opacity(0)
                } else {
                    ButtonView(controller: controller, button: button, layout: $layout, gameId: gameId)
                        .reportsControlFrame()
                        .scaleEffect(layout.buttons[button.id]?.scale ?? 1.0)
                        .offset(layout.buttons[button.id]?.offset ?? .zero)
                }
            }
        }
    }
}
