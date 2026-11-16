# MegaLayoutSwitcher 🇺🇦

**Free, open-source keyboard layout switcher for macOS, made in Ukraine.**
Typed `ghbdsn` instead of `привіт`? Tap **Option** and it becomes `привіт`, and the layout switches to Ukrainian. Works both ways: `руддщ` → `hello`.

A lightweight alternative to Punto Switcher, Caramba Switcher and Boomkey for Mac, built for **Ukrainian ↔ English** (works with any Cyrillic ↔ Latin pair).

> **UA:** Безкоштовний перемикач розкладки клавіатури для macOS з відкритим кодом. Набрали `ghbdsn` замість `привіт`? Натисніть **Option** і текст виправиться, а розкладка перемкнеться. Українська ↔ англійська. Альтернатива Punto Switcher для Mac.

## Features

- **One tap of Option** converts text typed in the wrong layout and switches the layout.
- **Converts only the wrong part.** `я зараз скину згдд куйгуіе` → `я зараз скину pull request`. Words are checked with the built-in macOS spellchecker (Ukrainian + English).
- **Tap again to undo.**
- **Works everywhere:** TextEdit, Notes, Safari, Chrome, Slack, Telegram and other Electron apps.
- **Plays well with Caps Lock layout switching.** Text typed before you switch layout yourself is never touched.
- `⌥`-characters (`©`, `–`, …) still type normally. Off in terminals and IDEs.
- Tiny menu bar app, no Dock icon, a few hundred lines of Swift you can read in one sitting.

## Privacy

The app sees every keystroke (that's how it works), so to be explicit:

- No network code, no analytics, no clipboard use.
- Typed keys live only in memory, as keycodes, and are wiped on click, Enter, arrows, app switch, or a 3 s pause.
- Words are checked with the built-in macOS spellchecker. It runs on your Mac, no network.
- Nothing is written to disk. Password fields are protected by macOS Secure Input; the app never sees them.

## Install

Requires macOS 14+ and Xcode Command Line Tools (`xcode-select --install`).

1. Create a signing certificate so macOS keeps permissions across rebuilds:
   Keychain Access → Certificate Assistant → Create a Certificate…
   Name `MegaSwitcher Dev`, Identity Type *Self-Signed Root*, Certificate Type *Code Signing*.
2. Build and run:
   ```sh
   ./build.sh && open build/MegaLayoutSwitcher.app
   ```
   Always launch via `open` (or copy the app to `/Applications`). Running the binary from a terminal gives the permissions to the terminal instead.
3. Grant **Input Monitoring** and **Accessibility** (the menu bar icon links to both), then quit and relaunch.

Permissions look granted but don't work? Reset them, then grant again:

```sh
tccutil reset Accessibility local.mega-layout-switcher
tccutil reset ListenEvent local.mega-layout-switcher
```

## Tests

```sh
./test.sh
```

Conversion cases (screen text → expected result) in `Tests/`. They use the layouts installed on your Mac (a Latin one + a Cyrillic one).

## Code map

- `KeyWatcher` — event tap, typed-keys buffer, Option-tap detection
- `Switcher` — conversion + excluded apps (terminals, IDEs)
- `WrongLayoutDetector` — decides which trailing words were typed in the wrong layout
- `KeyboardLayout` — enabled layouts, keycode → character (UCKeyTranslate)
- `Typer` — posts backspaces + unicode text; `delayBetweenEvents` is the Electron tuning knob

## License

MIT
