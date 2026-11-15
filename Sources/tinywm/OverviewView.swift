import AppKit
import StripEngine

/// The overview's click-capturing panel. It becomes key without activating tinywm, so plain keys
/// reach it and none reach the app in front.
final class OverviewPanel: NSPanel {
    override var canBecomeKey: Bool { true }
    override var canBecomeMain: Bool { false }
}

/// Reads the keys, pointer and scrolling the overview reacts to. Points are top-left based.
final class OverviewView: NSView {
    typealias Key = OverviewCommand

    var keys = OverviewKeys()
    var onKey: (Key) -> Void = { _ in }
    var onHover: (CGPoint) -> Void = { _ in }
    var onClick: (CGPoint) -> Void = { _ in }
    var onScroll: (CGFloat) -> Void = { _ in }

    override var isFlipped: Bool { true }
    override var acceptsFirstResponder: Bool { true }

    override func updateTrackingAreas() {
        super.updateTrackingAreas()
        for a in trackingAreas { removeTrackingArea(a) }
        addTrackingArea(NSTrackingArea(rect: .zero, options: [.mouseMoved, .activeAlways, .inVisibleRect], owner: self))
    }

    override func keyDown(with event: NSEvent) {
        let flags = event.modifierFlags
        let held = flags.intersection([.command, .control, .option])
        let keyCode = Int(event.keyCode)
        // The meta key with W A S D steers the overview even where the strip has those keys
        // doing something else.
        if held == .option || held == [.option, .control] || held == .command,
           let key = keys.metaCommand(keyCode: keyCode, option: held.contains(.option),
                                      control: held.contains(.control), command: held.contains(.command)) {
            return onKey(key)
        }
        guard held.isEmpty, let key = keys.command(keyCode: keyCode, shift: flags.contains(.shift)) else { return }
        onKey(key)
    }

    override func mouseMoved(with event: NSEvent) { onHover(convert(event.locationInWindow, from: nil)) }
    override func mouseDown(with event: NSEvent) { onClick(convert(event.locationInWindow, from: nil)) }

    override func scrollWheel(with event: NSEvent) {
        let dx = event.scrollingDeltaX, dy = event.scrollingDeltaY
        // A plain vertical wheel pans only with shift held, so it does not fight the rows' vertical layout.
        let delta = abs(dx) >= abs(dy) ? dx : (event.modifierFlags.contains(.shift) ? dy : 0)
        if delta != 0 { onScroll(delta) }
    }
}
