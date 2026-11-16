import AppKit

final class AppDelegate: NSObject, NSApplicationDelegate, NSMenuDelegate {
    private let watcher = KeyWatcher()
    private var statusItem: NSStatusItem!
    private var isEnabled = true

    func applicationDidFinishLaunching(_ notification: Notification) {
        statusItem = NSStatusBar.system.statusItem(withLength: NSStatusItem.variableLength)
        statusItem.button?.image = NSImage(systemSymbolName: "keyboard", accessibilityDescription: "MegaLayoutSwitcher")
        statusItem.menu = NSMenu()
        statusItem.menu?.delegate = self

        watcher.onOptionTap = { [weak self] typed in
            guard let self, self.isEnabled else { return nil }
            return Switcher.convert(typed)
        }

        NSWorkspace.shared.notificationCenter.addObserver(
            forName: NSWorkspace.didActivateApplicationNotification, object: nil, queue: .main
        ) { [weak self] _ in self?.watcher.clear() }

        if !CGPreflightListenEventAccess() { CGRequestListenEventAccess() }
        if !CGPreflightPostEventAccess() { CGRequestPostEventAccess() }
        _ = watcher.start()
        updateIcon()
    }

    // MARK: Menu

    func menuNeedsUpdate(_ menu: NSMenu) {
        _ = watcher.start() // retry, in case permissions were just granted
        updateIcon()
        menu.removeAllItems()

        let enabledItem = NSMenuItem(title: "Enabled", action: #selector(toggleEnabled), keyEquivalent: "")
        enabledItem.state = isEnabled ? .on : .off
        menu.addItem(enabledItem)
        menu.addItem(.separator())

        menu.addItem(permissionItem("Input Monitoring", granted: CGPreflightListenEventAccess(), pane: "Privacy_ListenEvent"))
        menu.addItem(permissionItem("Accessibility", granted: CGPreflightPostEventAccess(), pane: "Privacy_Accessibility"))
        if !watcher.isRunning {
            let hint = NSMenuItem(title: "Granted Input Monitoring? Quit and relaunch.", action: nil, keyEquivalent: "")
            hint.isEnabled = false
            menu.addItem(hint)
        }
        menu.addItem(.separator())

        menu.addItem(NSMenuItem(title: "Quit", action: #selector(NSApplication.terminate(_:)), keyEquivalent: "q"))
        for item in menu.items where item.action != #selector(NSApplication.terminate(_:)) {
            item.target = self
        }
    }

    private func permissionItem(_ name: String, granted: Bool, pane: String) -> NSMenuItem {
        let title = granted ? "✅ \(name)" : "❌ \(name) — Open Settings…"
        let item = NSMenuItem(title: title, action: granted ? nil : #selector(openSettings(_:)), keyEquivalent: "")
        item.representedObject = pane
        return item
    }

    @objc private func openSettings(_ sender: NSMenuItem) {
        guard let pane = sender.representedObject as? String,
              let url = URL(string: "x-apple.systempreferences:com.apple.preference.security?\(pane)") else { return }
        NSWorkspace.shared.open(url)
    }

    @objc private func toggleEnabled() {
        isEnabled.toggle()
        watcher.clear()
        updateIcon()
    }

    private func updateIcon() {
        statusItem.button?.appearsDisabled = !(isEnabled && watcher.isRunning)
    }
}
