import Carbon
import Foundation

/// Posts synthetic keystrokes. Every event is tagged with `marker` so KeyWatcher ignores it.
enum Typer {
    static let marker: Int64 = 0x4D45_4741 // "MEGA"

    /// Pause after each posted event. The main knob for Electron apps (Slack, Telegram).
    private static let delayBetweenEvents: useconds_t = 3_000

    private static let queue = DispatchQueue(label: "MegaLayoutSwitcher.Typer")

    static func replace(count: Int, with text: String, then completion: @escaping () -> Void) {
        queue.async {
            for _ in 0..<count {
                post(keyCode: CGKeyCode(kVK_Delete), text: nil)
            }
            for character in text {
                post(keyCode: 0, text: String(character))
            }
            DispatchQueue.main.async(execute: completion)
        }
    }

    private static func post(keyCode: CGKeyCode, text: String?) {
        for isDown in [true, false] {
            guard let event = CGEvent(keyboardEventSource: nil, virtualKey: keyCode, keyDown: isDown) else { continue }
            event.flags = []
            event.setIntegerValueField(.eventSourceUserData, value: marker)
            if let text {
                let utf16 = Array(text.utf16)
                event.keyboardSetUnicodeString(stringLength: utf16.count, unicodeString: utf16)
            }
            event.post(tap: .cghidEventTap)
            usleep(delayBetweenEvents)
        }
    }
}
