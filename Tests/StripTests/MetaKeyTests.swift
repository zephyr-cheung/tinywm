import Testing
@testable import StripEngine

@Suite struct MetaKeyBindingTests {
    let ctrlOpt = MetaKeyBindings.control | MetaKeyBindings.option
    let n = 45, left = 123

    @Test func controlOptionShortcutsBecomeRightCommandChords() {
        let b = MetaKeyBindings([
            ("focus.left", n, ctrlOpt),
            ("move.left", n, ctrlOpt | MetaKeyBindings.shift),
            ("column.example", left, ctrlOpt | MetaKeyBindings.command),
        ])
        #expect(b.action(keyCode: n, shift: false, option: false) == "focus.left")
        #expect(b.action(keyCode: n, shift: true, option: false) == "move.left")
        // ⌘ is the meta key itself, so an extra ⌘ in a binding is pressed as ⌥.
        #expect(b.action(keyCode: left, shift: false, option: true) == "column.example")
        #expect(b.action(keyCode: left, shift: false, option: false) == nil)
    }

    @Test func shortcutsWithoutControlOptionAreIgnored() {
        let b = MetaKeyBindings([("other", n, MetaKeyBindings.command)])
        #expect(b.actions.isEmpty)
    }

    @Test func theFirstActionKeepsAChordBothWouldUse() {
        let b = MetaKeyBindings([("a", n, ctrlOpt), ("b", n, ctrlOpt)])
        #expect(b.action(keyCode: n, shift: false, option: false) == "a")
    }

    @Test func menusShowTheChosenMetaKey() {
        let m = ctrlOpt | MetaKeyBindings.shift
        #expect(MetaKeyBindings.display(keyName: "N", modifiers: m, mode: .controlOption) == "⌃⌥⇧N")
        #expect(MetaKeyBindings.display(keyName: "N", modifiers: m, mode: .rightCommand) == "Right⌘ ⇧N")
        #expect(MetaKeyBindings.display(keyName: "←", modifiers: ctrlOpt | MetaKeyBindings.command, mode: .rightCommand) == "Right⌘ ⌥←")
    }

    @Test func theMetaKeyIsReadFromEventFlags() {
        let command: UInt64 = 0x100000, leftCommandBit: UInt64 = 0x08, rightCommandBit: UInt64 = 0x10
        #expect(MetaModifier.rightCommand.isHeld(flags: command | rightCommandBit))
        #expect(!MetaModifier.rightCommand.isHeld(flags: command | leftCommandBit))
        #expect(MetaModifier.controlOption.isHeld(flags: 0x40000 | 0x80000))
        #expect(!MetaModifier.controlOption.isHeld(flags: 0x40000))
    }
}

@Suite struct OptionMetaKeyTests {
    let ctrlOpt = MetaKeyBindings.control | MetaKeyBindings.option
    let a = 0, d = 2, space = 49, up = 126

    @Test func optionShortcutsBecomeOptionChords() {
        let b = MetaKeyBindings([
            ("focus-left", a, ctrlOpt),
            ("move-left", a, ctrlOpt | MetaKeyBindings.shift),
        ], mode: .option)
        #expect(b.action(keyCode: a, shift: false, option: true) == "focus-left")
        #expect(b.action(keyCode: a, shift: true, option: true) == "move-left")
        // The ⌥ in the event is the meta key itself, so the lookup never asks for an extra one.
        #expect(b.action(keyCode: a, shift: false, option: false) == "focus-left")
        #expect(b.action(keyCode: d, shift: false, option: true) == nil)
    }

    @Test func anExtraOptionBecomesTheMetaKeyItself() {
        // The shipped arrow-key workspace shortcuts carry an extra ⌥, which ⌥ as the meta key
        // already is: ⌥↑ stays ⌥↑.
        let b = MetaKeyBindings([("workspace-up-arrow", up, ctrlOpt | MetaKeyBindings.command)], mode: .option)
        #expect(b.action(keyCode: up, shift: false, option: true) == "workspace-up-arrow")
        // ⇧ is still told apart.
        let moved = MetaKeyBindings([("workspace-move-up-arrow", up, ctrlOpt | MetaKeyBindings.command | MetaKeyBindings.shift)],
                                    mode: .option)
        #expect(moved.action(keyCode: up, shift: true, option: true) == "workspace-move-up-arrow")
        #expect(moved.action(keyCode: up, shift: false, option: true) == nil)
    }

    @Test func optionKeysWithoutTheBaseAreIgnored() {
        let b = MetaKeyBindings([("plain", space, MetaKeyBindings.shift)], mode: .option)
        #expect(b.actions.isEmpty)
    }

    @Test func menusShowOptionAlone() {
        #expect(MetaKeyBindings.display(keyName: "A", modifiers: ctrlOpt, mode: .option) == "⌥A")
        #expect(MetaKeyBindings.display(keyName: "A", modifiers: ctrlOpt | MetaKeyBindings.shift, mode: .option) == "⌥⇧A")
        #expect(MetaKeyBindings.display(keyName: "↑", modifiers: ctrlOpt | MetaKeyBindings.command, mode: .option) == "⌥↑")
    }

    @Test func theOptionKeyIsReadFromEventFlags() {
        let option: UInt64 = 0x80000, command: UInt64 = 0x100000
        #expect(MetaModifier.option.isHeld(flags: option))
        #expect(!MetaModifier.option.isHeld(flags: command))
        #expect(MetaModifier.option.isHeld(flags: option | command))
    }

    @Test func optionModeReadsKeysThroughTheTap() {
        #expect(MetaModifier.option.readsKeysThroughTheTap)
        #expect(MetaModifier.rightCommand.readsKeysThroughTheTap)
        #expect(!MetaModifier.controlOption.readsKeysThroughTheTap)
    }

    @Test func theMoveHintNamesTheOptionKey() {
        #expect(MoveHint.text(bindings: StripActions.defaultBindings, meta: .option)
            == "Hold ⌥ and press H J K L or the arrow keys to move around.")
    }
}
