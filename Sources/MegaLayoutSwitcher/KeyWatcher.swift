import AppKit
import Carbon

/// What was typed since the last "break" (click, Enter, pause, app switch...).
/// Stores physical keys, so the same keys can be re-read in any layout.
struct TypedText {
    var keys: [TypedKey] = []
    var layoutID: String?
    var wasJustConverted = false
}

/// Watches the keyboard and calls `onOptionTap` when Option is tapped alone.
final class KeyWatcher {
    /// Receives the typed text, returns it after conversion (nil = nothing happened).
    var onOptionTap: (TypedText) -> TypedText? = { _ in nil }

    private static let optionTapMaxDuration: TimeInterval = 0.3
    private static let maxPauseBetweenKeys: TimeInterval = 3

    private var typed = TypedText()
    private var lastKeyTime: TimeInterval = 0
    private var optionDownTime: TimeInterval?
    private var tap: CFMachPort?

    var isRunning: Bool { tap != nil }

    /// Fails until Input Monitoring is granted.
    func start() -> Bool {
        guard tap == nil else { return true }

        let types: [CGEventType] = [.keyDown, .flagsChanged, .leftMouseDown, .rightMouseDown, .otherMouseDown]
        let mask = types.reduce(CGEventMask(0)) { $0 | (1 << $1.rawValue) }
        let callback: CGEventTapCallBack = { _, type, event, userInfo in
            let watcher = Unmanaged<KeyWatcher>.fromOpaque(userInfo!).takeUnretainedValue()
            watcher.handle(type, event)
            return Unmanaged.passUnretained(event)
        }
        guard let tap = CGEvent.tapCreate(
            tap: .cgSessionEventTap, place: .headInsertEventTap, options: .listenOnly,
            eventsOfInterest: mask, callback: callback,
            userInfo: Unmanaged.passUnretained(self).toOpaque()
        ) else { return false }

        let source = CFMachPortCreateRunLoopSource(nil, tap, 0)
        CFRunLoopAddSource(CFRunLoopGetMain(), source, .commonModes)
        CGEvent.tapEnable(tap: tap, enable: true)
        self.tap = tap
        return true
    }

    func clear() {
        typed = TypedText()
    }

    private func handle(_ type: CGEventType, _ event: CGEvent) {
        if type == .tapDisabledByTimeout || type == .tapDisabledByUserInput {
            if let tap { CGEvent.tapEnable(tap: tap, enable: true) }
            return
        }
        if event.getIntegerValueField(.eventSourceUserData) == Typer.marker { return }

        switch type {
        case .keyDown: handleKeyDown(event)
        case .flagsChanged: handleFlagsChanged(event)
        default: // mouse click
            optionDownTime = nil
            clear()
        }
    }

    private func handleKeyDown(_ event: CGEvent) {
        optionDownTime = nil

        let flags = event.flags
        if !flags.isDisjoint(with: [.maskCommand, .maskControl, .maskAlternate]) {
            clear()
            return
        }

        let now = ProcessInfo.processInfo.systemUptime
        if now - lastKeyTime > Self.maxPauseBetweenKeys { clear() }
        lastKeyTime = now

        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        typed.wasJustConverted = false
        if keyCode == kVK_Delete {
            if !typed.keys.isEmpty { typed.keys.removeLast() }
        } else if Self.isPrintable(keyCode) {
            // You switched layout yourself (Caps Lock): what came before was intended, start fresh.
            let layoutID = KeyboardLayout.current().id
            if typed.layoutID != layoutID { typed = TypedText(layoutID: layoutID) }
            typed.keys.append(TypedKey(
                keyCode: UInt16(keyCode),
                shift: flags.contains(.maskShift),
                capsLock: flags.contains(.maskAlphaShift)
            ))
        } else {
            clear() // Enter, Tab, Esc, arrows, Home/End, F-keys...
        }
    }

    private func handleFlagsChanged(_ event: CGEvent) {
        let keyCode = Int(event.getIntegerValueField(.keyboardEventKeycode))
        guard keyCode == kVK_Option || keyCode == kVK_RightOption else {
            optionDownTime = nil
            return
        }

        let now = ProcessInfo.processInfo.systemUptime
        let flags = event.flags
        let otherModifiersHeld = !flags.isDisjoint(with: [.maskShift, .maskControl, .maskCommand])

        if flags.contains(.maskAlternate) {
            optionDownTime = otherModifiersHeld ? nil : now
        } else if let downTime = optionDownTime, now - downTime < Self.optionTapMaxDuration {
            optionDownTime = nil
            if let converted = onOptionTap(typed) { typed = converted }
        } else {
            optionDownTime = nil
        }
    }

    /// Letters, digits, punctuation and space on the main block (keycodes 0...50, minus Return and Tab).
    private static func isPrintable(_ keyCode: Int) -> Bool {
        (0...50).contains(keyCode) && keyCode != kVK_Return && keyCode != kVK_Tab
    }
}
