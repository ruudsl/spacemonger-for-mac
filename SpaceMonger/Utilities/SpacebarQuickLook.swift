import SwiftUI
import AppKit

/// Adds Finder-style spacebar Quick Look without hijacking the Space key while
/// the user is typing. A local key monitor fires `action` only when the key
/// window's first responder is not a text field/editor.
struct SpacebarQuickLook: ViewModifier {
    /// Returns `true` if it handled the key (so the event is consumed).
    let action: () -> Bool
    @State private var monitor: Any?

    func body(content: Content) -> some View {
        content
            .onAppear { install() }
            .onDisappear { remove() }
    }

    private func install() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            guard event.keyCode == 49 else { return event }   // 49 == Space
            let responder = event.window?.firstResponder
            // While editing text, the first responder is the window's field
            // editor (an NSText/NSTextView) — let Space type a space.
            if responder is NSText { return event }
            if let view = responder as? NSView, view is NSTextView { return event }
            return action() ? nil : event
        }
    }

    private func remove() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}

extension View {
    func spacebarQuickLook(_ action: @escaping () -> Bool) -> some View {
        modifier(SpacebarQuickLook(action: action))
    }
}

/// Routes key presses (arrows, Return, ⌘↑) to a handler unless the user is
/// typing in a text field. The handler returns `true` to consume the event.
struct MapKeyboard: ViewModifier {
    let handler: (NSEvent) -> Bool
    @State private var monitor: Any?

    func body(content: Content) -> some View {
        content
            .onAppear { install() }
            .onDisappear { remove() }
    }

    private func install() {
        guard monitor == nil else { return }
        monitor = NSEvent.addLocalMonitorForEvents(matching: .keyDown) { event in
            let responder = event.window?.firstResponder
            if responder is NSText { return event }
            if let view = responder as? NSView, view is NSTextView { return event }
            return handler(event) ? nil : event
        }
    }

    private func remove() {
        if let monitor { NSEvent.removeMonitor(monitor) }
        monitor = nil
    }
}

extension View {
    func mapKeyboard(_ handler: @escaping (NSEvent) -> Bool) -> some View {
        modifier(MapKeyboard(handler: handler))
    }
}
