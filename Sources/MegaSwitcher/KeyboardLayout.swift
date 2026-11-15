import Carbon

struct TypedKey {
    let keyCode: UInt16
    let shift: Bool
    let capsLock: Bool
}

/// A keyboard layout installed and enabled in System Settings.
struct KeyboardLayout {
    let source: TISInputSource

    var id: String {
        guard let pointer = TISGetInputSourceProperty(source, kTISPropertyInputSourceID) else { return "" }
        return Unmanaged<CFString>.fromOpaque(pointer).takeUnretainedValue() as String
    }

    var isCyrillic: Bool {
        let letterA = TypedKey(keyCode: UInt16(kVK_ANSI_A), shift: false, capsLock: false)
        guard let scalar = character(for: letterA).unicodeScalars.first else { return false }
        return (0x0400...0x04FF).contains(scalar.value)
    }

    static func current() -> KeyboardLayout {
        KeyboardLayout(source: TISCopyCurrentKeyboardLayoutInputSource().takeRetainedValue())
    }

    static func enabled() -> [KeyboardLayout] {
        let filter = [
            kTISPropertyInputSourceType as String: kTISTypeKeyboardLayout as String,
            kTISPropertyInputSourceIsSelectCapable as String: true,
        ] as CFDictionary
        let sources = TISCreateInputSourceList(filter, false).takeRetainedValue() as! [TISInputSource]
        return sources.map(KeyboardLayout.init)
    }

    static func withID(_ id: String) -> KeyboardLayout? {
        enabled().first { $0.id == id }
    }

    /// Latin ↔ Cyrillic: the first enabled layout of the other script.
    func counterpart() -> KeyboardLayout? {
        KeyboardLayout.enabled().first { $0.isCyrillic != isCyrillic }
    }

    func select() {
        TISSelectInputSource(source)
    }

    func character(for key: TypedKey) -> String {
        guard let pointer = TISGetInputSourceProperty(source, kTISPropertyUnicodeKeyLayoutData) else { return "" }
        let data = Unmanaged<CFData>.fromOpaque(pointer).takeUnretainedValue()

        var modifiers: UInt32 = 0
        if key.shift { modifiers |= UInt32(shiftKey >> 8) }
        if key.capsLock { modifiers |= UInt32(alphaLock >> 8) }

        var deadKeyState: UInt32 = 0
        var chars = [UniChar](repeating: 0, count: 4)
        var length = 0
        CFDataGetBytePtr(data).withMemoryRebound(to: UCKeyboardLayout.self, capacity: 1) { layout in
            _ = UCKeyTranslate(
                layout, key.keyCode, UInt16(kUCKeyActionDown), modifiers, UInt32(LMGetKbdType()),
                OptionBits(1 << kUCKeyTranslateNoDeadKeysBit), &deadKeyState, chars.count, &length, &chars
            )
        }
        return String(utf16CodeUnits: chars, count: length)
    }
}
