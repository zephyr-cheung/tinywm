public enum OverviewCommand: Equatable, Sendable { case left, right, up, down, next, previous, confirm, cancel }

/// What each key does while the overview is open, built from the resolved bindings.
public struct OverviewKeys: Equatable, Sendable {
    private var plain: [Int: OverviewCommand] = [:]
    /// The meta key in force, so the cross below is read with the same modifier the rest uses.
    public var meta: MetaModifier

    /// The cross steers the overview whatever those keys do on the strip, so up and down work
    /// even when only the focus letters are bound: W A S D, and the arrows beside them.
    public static let cross: [Int: OverviewCommand] = [
        13: .up, 1: .down, 0: .left, 2: .right,
        126: .up, 125: .down, 123: .left, 124: .right,
    ]

    /// Plain keys: the focus keys (letters and arrows), the arrows always, Tab, Return and Esc.
    /// The cross below is only read with the meta key held.
    public init(bindings: [String: MetaKeyBindings.Chord] = StripActions.defaultBindings,
                meta: MetaModifier = .rightCommand) {
        self.meta = meta
        let arrows = [(123, OverviewCommand.left), (124, .right), (126, .up), (125, .down)]
        for (code, command) in arrows { plain[code] = command }
        for (name, chord) in bindings where !chord.shift && !chord.option {
            if let command = Self.command(forAction: name), command != .confirm { plain[chord.keyCode] = command }
        }
        // These never move to a binding, so the overview can always be left.
        plain[48] = .next
        plain[36] = .confirm
        plain[76] = .confirm
        plain[53] = .cancel
    }

    /// The command for a key pressed without the meta key.
    public func command(keyCode: Int, shift: Bool) -> OverviewCommand? {
        if keyCode == 48 { return shift ? .previous : .next }
        if shift { return nil }
        return plain[keyCode]
    }

    /// The command for a key pressed with the meta key held: the W A S D cross, whatever the
    /// config binds to those keys. The overview never closes windows, so ⌥W means up there.
    public func metaCommand(keyCode: Int, option: Bool, control: Bool, command: Bool) -> OverviewCommand? {
        let held: Bool
        switch meta {
        case .option: held = option && !control && !command
        case .controlOption: held = option && control
        case .rightCommand: held = command
        }
        guard held else { return nil }
        return Self.cross[keyCode]
    }

    /// The cross command for a key the meta modifier was pressed with, for the tap's own path,
    /// where the meta key is held by definition.
    public static func cross(forKeyCode keyCode: Int) -> OverviewCommand? { cross[keyCode] }

    /// The command for an action fired through the meta key while the overview is open.
    /// Other actions are ignored then, so they cannot move real windows.
    public static func command(forAction name: String) -> OverviewCommand? {
        switch name {
        case "focus-left", "focus-left-arrow": .left
        case "focus-right", "focus-right-arrow": .right
        case "focus-up", "focus-up-arrow": .up
        case "focus-down", "focus-down-arrow": .down
        case "overview": .confirm
        default: nil
        }
    }
}
