import AppKit

/// Re-types the wrong-layout part of the typed text in the other layout and switches the system layout.
enum Switcher {
    private static let excludedBundleIDs: Set<String> = [
        "com.apple.Terminal",
        "com.googlecode.iterm2",
        "com.mitchellh.ghostty",
        "net.kovidgoyal.kitty",
        "com.apple.dt.Xcode",
        "com.microsoft.VSCode",
        "com.todesktop.230313mzl4w4u92", // Cursor
    ]
    private static let excludedBundlePrefixes = ["com.jetbrains."]

    /// Returns what the typed text is after conversion, or nil if nothing happened.
    static func convert(_ typed: TypedText) -> TypedText? {
        guard !typed.keys.isEmpty, !isFrontmostAppExcluded() else { return nil }

        let source = typed.layoutID.flatMap(KeyboardLayout.withID) ?? KeyboardLayout.current()
        guard let target = source.counterpart() else { return nil }

        // Right after a conversion, another tap reverts exactly that part.
        let count = typed.wasJustConverted
            ? typed.keys.count
            : WrongLayoutDetector.wrongTailLength(of: typed.keys, typedIn: source, intended: target)
        guard count > 0 else { return nil }

        let keys = Array(typed.keys.suffix(count))
        let text = keys.map(target.character).joined()
        Typer.replace(count: count, with: text) {
            target.select()
        }
        return TypedText(keys: keys, layoutID: target.id, wasJustConverted: true)
    }

    private static func isFrontmostAppExcluded() -> Bool {
        guard let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return false }
        return excludedBundleIDs.contains(bundleID)
            || excludedBundlePrefixes.contains { bundleID.hasPrefix($0) }
    }
}
