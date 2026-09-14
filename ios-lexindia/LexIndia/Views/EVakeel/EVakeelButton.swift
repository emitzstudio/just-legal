//
//  EVakeelButton.swift
//  LexIndia
//
//  The floating E-Vakeel button: a glowing accent circle that lives above
//  the app. One gesture handles everything with zero recognition delay —
//  the circle sticks to the finger the instant a drag starts, springs to
//  the nearest edge on release, remembers its dock, and a plain tap opens
//  the assistant.
//

import SwiftUI

/// Full-screen transparent layer hosting the draggable button.
struct EVakeelFloatingLayer: View {
    @Environment(UIState.self) private var ui

    var body: some View {
        GeometryReader { geo in
            EVakeelFloatingButton(container: geo.size)
        }
        .opacity(ui.evakeelPresented ? 0 : 1)
        .animation(.easeOut(duration: 0.2), value: ui.evakeelPresented)
    }
}

private struct EVakeelFloatingButton: View {
    @Environment(UserDataStore.self) private var store
    @Environment(UIState.self) private var ui

    let container: CGSize

    /// Centre of the button while a drag is live; nil when resting.
    @State private var dragPoint: CGPoint?
    /// Resting centre captured when the current touch began, so every move
    /// maps 1:1 from the finger's translation with no initial jump.
    @State private var touchStart: CGPoint = .zero
    @State private var isPressed: Bool = false
    @State private var isDragging: Bool = false
    @State private var glowPulse: Bool = false

    private let diameter: CGFloat = 58
    private let margin: CGFloat = 18
    /// Movement below this is a tap; above it, a drag.
    private let dragThreshold: CGFloat = 6

    /// Where the button rests when not being dragged.
    private var restingPoint: CGPoint {
        let x = store.evakeelDockOnRight
            ? container.width - margin - diameter / 2
            : margin + diameter / 2
        let y = min(max(container.height * store.evakeelDockY, 90), container.height - 130)
        return CGPoint(x: x, y: y)
    }

    var body: some View {
        EVakeelButtonFace(diameter: diameter)
            .background(
                Circle()
                    .fill(LexColor.brand.opacity(0.4))
                    .blur(radius: 12)
                    .scaleEffect(glowPulse ? 1.3 : 1.05)
                    .animation(.easeInOut(duration: 1.9).repeatForever(autoreverses: true), value: glowPulse)
            )
            .shadow(color: LexColor.brand.opacity(0.45), radius: 12, x: 0, y: 5)
            .scaleEffect(isDragging ? 1.1 : (isPressed ? 0.92 : 1))
            .animation(.spring(duration: 0.25), value: isDragging)
            .animation(.spring(duration: 0.2), value: isPressed)
            .position(dragPoint ?? restingPoint)
            .gesture(touchGesture)
            .sensoryFeedback(.impact(weight: .light), trigger: isDragging)
            .onAppear { glowPulse = true }
            .accessibilityLabel("E-Vakeel, your digital legal assistant")
            .accessibilityHint("Opens the assistant. Drag to reposition.")
            .accessibilityAddTraits(.isButton)
    }

    /// A single `minimumDistance: 0` drag receives the touch immediately —
    /// no tap/drag disambiguation delay, no dead zone. While dragging,
    /// position updates run inside a transaction with animations disabled
    /// so the circle stays pinned under the finger; only the release snap
    /// animates. Releasing within the threshold counts as a tap.
    private var touchGesture: some Gesture {
        DragGesture(minimumDistance: 0, coordinateSpace: .global)
            .onChanged { value in
                if !isPressed {
                    isPressed = true
                    touchStart = dragPoint ?? restingPoint
                }
                let distance = hypot(value.translation.width, value.translation.height)
                if !isDragging && distance > dragThreshold {
                    isDragging = true
                }
                guard isDragging else { return }
                var transaction = Transaction()
                transaction.disablesAnimations = true
                withTransaction(transaction) {
                    dragPoint = clamped(CGPoint(
                        x: touchStart.x + value.translation.width,
                        y: touchStart.y + value.translation.height
                    ))
                }
            }
            .onEnded { value in
                isPressed = false
                let wasDragging = isDragging
                isDragging = false
                guard wasDragging else {
                    ui.openEVakeel()
                    return
                }
                // Project a little momentum so a flick lands on the side
                // the finger was heading toward.
                let projectedX = touchStart.x + value.predictedEndTranslation.width
                let endY = touchStart.y + value.translation.height
                let snapRight = projectedX > container.width / 2
                let yFraction = Double(endY / max(container.height, 1))
                store.setEVakeelDock(onRight: snapRight, yFraction: yFraction)
                withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                    dragPoint = nil
                }
            }
    }

    /// Keeps the whole circle on screen and clear of the tab bar while
    /// dragging.
    private func clamped(_ point: CGPoint) -> CGPoint {
        CGPoint(
            x: min(max(point.x, diameter / 2 + 6), container.width - diameter / 2 - 6),
            y: min(max(point.y, 76), max(container.height - 110, 76))
        )
    }
}
