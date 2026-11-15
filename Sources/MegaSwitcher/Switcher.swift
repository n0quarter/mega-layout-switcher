import AppKit

/// Re-types the buffered keys in the other layout and switches the system layout.
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

    /// Returns the layout ID the text was converted to, or nil if nothing happened.
    static func convert(_ typed: TypedText) -> String? {
        guard !typed.keys.isEmpty, !isFrontmostAppExcluded() else { return nil }

        let source = typed.layoutID.flatMap(KeyboardLayout.withID) ?? KeyboardLayout.current()
        guard let target = source.counterpart() else { return nil }

        let text = typed.keys.map(target.character).joined()
        Typer.replace(count: typed.keys.count, with: text) {
            target.select()
        }
        return target.id
    }

    private static func isFrontmostAppExcluded() -> Bool {
        guard let bundleID = NSWorkspace.shared.frontmostApplication?.bundleIdentifier else { return false }
        return excludedBundleIDs.contains(bundleID)
            || excludedBundlePrefixes.contains { bundleID.hasPrefix($0) }
    }
}
