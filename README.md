# MegaSwitcher

Menu bar app: tap Option alone → the text you just typed in the wrong layout is re-typed in the other one (Latin ↔ Cyrillic), and the layout switches. Tap again to revert.

Only the wrong part is converted: `я зараз скину згдд куйгуіе` → `я зараз скину pull request`. Words are checked against the built-in macOS spellchecker in both languages.

Requires macOS 14+ and Xcode Command Line Tools (`xcode-select --install`). Off in terminals and IDEs (list in `Switcher.swift`).

## Privacy

The app sees every keystroke (that's how it works), so to be explicit:

- No network code, no analytics, no clipboard use.
- Typed keys live only in memory, as keycodes, and are wiped on click, Enter, arrows, app switch, or a 3 s pause.
- To find the wrong-layout words, words are checked with the built-in macOS spellchecker. It runs on your Mac, no network.
- Nothing is written to disk. Password fields are protected by macOS Secure Input; the app never sees them.

## Build & run

```sh
./build.sh && open build/MegaSwitcher.app
```

Always launch via `open`. Running the binary from a terminal gives the permissions to the terminal instead.

## One-time setup

1. Create a signing cert so permissions survive rebuilds:
   Keychain Access → Certificate Assistant → Create a Certificate…
   Name `MegaSwitcher Dev`, Identity Type *Self-Signed Root*, Certificate Type *Code Signing*.
2. Grant **Input Monitoring** and **Accessibility** (the menu links to both), then quit and relaunch.

Permissions look granted but don't work (common after ad-hoc builds)? Reset them, then grant again:

```sh
tccutil reset Accessibility local.mega-switcher
tccutil reset ListenEvent local.mega-switcher
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
