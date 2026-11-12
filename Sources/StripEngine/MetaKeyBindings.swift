import WindowCore
/// Which key acts as tinywm's modifier.
public enum MetaModifier: String, Codable, Sendable, CaseIterable {
    /// Right ⌘ alone, read from raw key events. Keys pressed with it never reach apps.
    case rightCommand
    /// ⌃⌥ together, through system hotkeys.
    case controlOption
    /// ⌥ alone, read from raw key events. Only keys tinywm has a shortcut for never reach apps.
    case option
}

extension MetaModifier {
    /// Whether the meta key is held, read from an event's raw flags (CGEventFlags). Mouse
    /// events carry the same flags as key events, including the bit for each side's ⌘ key.
    public func isHeld(flags: UInt64) -> Bool {
        let control: UInt64 = 0x40000, option: UInt64 = 0x80000, command: UInt64 = 0x100000
        let rightCommand: UInt64 = 0x10
        switch self {
        case .rightCommand: return flags & command != 0 && flags & rightCommand != 0
        case .controlOption: return flags & control != 0 && flags & option != 0
        case .option: return flags & option != 0
        }
    }

    /// Whether keys go to tinywm through its own event tap rather than through system hotkeys.
    /// ⌃⌥ is left to Carbon, which needs no Accessibility grant to read the keyboard.
    public var readsKeysThroughTheTap: Bool {
        switch self {
        case .rightCommand, .option: return true
        case .controlOption: return false
        }
    }
}

/// Translates tinywm's stored shortcuts, written as ⌃⌥ plus extras, into the chords of the
/// meta key in force: right ⌘ chords, or ⌥ chords.
///
/// Modifier values are Carbon's (`controlKey`, `optionKey`, `shiftKey`, `cmdKey`), so this stays
/// free of Carbon and testable. With right ⌘ as the meta key, ⌘ itself cannot be an extra, so a
/// shortcut's extra ⌘ becomes ⌥.
public struct MetaKeyBindings: Equatable, Sendable {
    public struct Chord: Hashable, Sendable {
        public var keyCode: Int
        public var shift: Bool
        public var option: Bool
        /// Only with right ⌘ as the meta key; ⌃⌥ already holds control.
        public var control: Bool
        public init(keyCode: Int, shift: Bool, option: Bool, control: Bool = false) {
            self.keyCode = keyCode; self.shift = shift; self.option = option; self.control = control
        }
    }

    public static let control = 0x1000
    public static let option = 0x0800
    public static let shift = 0x0200
    public static let command = 0x0100
    /// Stands for an extra control key in a right ⌘ chord, which ⌃⌥ shortcuts cannot carry.
    public static let extraControl = Shortcut.extraControl

    /// The meta key these chords are read with. With ⌥ as the meta key there is no room for an
    /// extra ⌥, which the defaults only use for the arrow-key workspace shortcuts.
    public var mode: MetaModifier
    /// Action names by the chord that triggers them with the meta key held.
    public private(set) var actions: [Chord: String] = [:]

    public init(mode: MetaModifier = .controlOption) {
        self.mode = mode
    }

    /// Builds the map from `(action, keyCode, Carbon modifiers)` shortcuts. Only shortcuts based on
    /// ⌃⌥ carry over; the first action wins if two translate to the same chord.
    public init(_ shortcuts: [(action: String, keyCode: Int, modifiers: Int)], mode: MetaModifier = .controlOption) {
        self.mode = mode
        for s in shortcuts {
            guard let chord = Self.chord(keyCode: s.keyCode, modifiers: s.modifiers, mode: mode),
                  actions[chord] == nil else { continue }
            actions[chord] = s.action
        }
    }

    /// Reads a stored shortcut, which is always written as ⌃⌥ plus extras, as a chord of `mode`.
    public static func chord(keyCode: Int, modifiers: Int, mode: MetaModifier = .controlOption) -> Chord? {
        switch mode {
        case .controlOption, .rightCommand:
            let base = control | option
            guard modifiers & base == base else { return nil }
            return Chord(keyCode: keyCode, shift: modifiers & shift != 0, option: modifiers & command != 0,
                         control: modifiers & extraControl != 0)
        case .option:
            guard modifiers & option != 0 else { return nil }
            // ⌥ is the meta key, so an extra ⌥ in a shortcut (the arrow-key workspace defaults)
            // is the same press; there is no further ⌘ or ⌃ to carry.
            return Chord(keyCode: keyCode, shift: modifiers & shift != 0, option: false)
        }
    }

    /// The action for a key pressed with the meta key held, given the other modifiers held with
    /// it. With ⌥ as the meta key the ⌥ in `option` is the meta key itself, so no chord has one.
    public func action(keyCode: Int, shift: Bool, option: Bool, control: Bool = false) -> String? {
        let plain = mode == .option
        return actions[Chord(keyCode: keyCode, shift: shift, option: plain ? false : option,
                             control: plain ? false : control)]
    }

    /// How a shortcut reads in menus for the given meta key.
    public static func display(keyName: String, modifiers: Int, mode: MetaModifier) -> String {
        switch mode {
        case .controlOption:
            var s = ""
            if modifiers & control != 0 { s += "⌃" }
            if modifiers & option != 0 { s += "⌥" }
            if modifiers & shift != 0 { s += "⇧" }
            if modifiers & command != 0 { s += "⌘" }
            return s + keyName
        case .rightCommand:
            var s = "Right⌘ "
            if modifiers & extraControl != 0 { s += "⌃" }
            if modifiers & shift != 0 { s += "⇧" }
            if modifiers & command != 0 { s += "⌥" }
            return s + keyName
        case .option:
            // ⌥ is the meta key itself; only ⇧ can join it.
            var s = "⌥"
            if modifiers & shift != 0 { s += "⇧" }
            return s + keyName
        }
    }
}
