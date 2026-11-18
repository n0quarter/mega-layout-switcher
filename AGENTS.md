# MegaLayoutSwitcher — project notes

macOS menu bar app (Swift, no Dock icon): tap Option alone → text typed in the wrong layout is re-typed in the other one (Latin ↔ Cyrillic) and the system layout switches. Tap again to revert.
Public repo: https://github.com/n0quarter/mega-layout-switcher (MIT). Personal tool first; keep it small and readable.

**Open source: everything committed is public.** Never commit secrets, personal data, local paths or machine-specific config. Keep those in `.env` or other git-ignored files (`.gitignore` already covers `.env`, `build/`, `.build/`). Check `git status` and the diff before every push.

## State (Nov 2026)
- v1 works daily on the owner's MacBook (U.S. + Ukrainian-PC layouts): TextEdit, Notes, Safari, Chrome, Slack, Telegram.
- Installed copy: `/Applications/MegaLayoutSwitcher.app`. Raycast finds it there.
- 30 conversion tests pass (`./test.sh`).

## How it works
- `KeyWatcher`: listen-only CGEventTap. Buffers the physical keys typed (keycode + Shift/Caps), never characters. The buffer is cleared on click, Enter/Tab/Esc/arrows, Cmd/Ctrl/Option shortcuts, an app switch, or a 3 s pause. A layout switch you make yourself (Caps Lock) starts a fresh buffer.
- Option tap = Option down → up within 300 ms with nothing in between.
- `WrongLayoutDetector`: works back from the end word by word and checks each word with `NSSpellChecker` in both languages. Only the wrong-layout tail is converted.
  - The rules are in code comments: script check, letter-count tiebreak, ambiguous one-letter words, last-word fallback.
- `Switcher`: decides what to convert. If the last action was a conversion, the next tap reverts exactly that part. Also holds the excluded apps (terminals, IDEs).
- `Typer`: posts N backspaces, then the text via `CGEventKeyboardSetUnicodeString`, one char per event with a 3 ms delay (the knob for Electron). Every event is tagged with `eventSourceUserData` so the tap ignores its own events.
- `KeyboardLayout`: wraps TIS/UCKeyTranslate. The target layout is the first enabled layout of the other script, nothing hardcoded.

## Key decisions
- **Spellchecker, not an ML/LLM model.** It's fast (about 2 ms/word), local and deterministic. The next step if accuracy needs it is letter n-gram scoring, Punto-style.
- **Conservative:** the app never converts text that was correct as typed. Known misses: a typo at the start of the wrong part, and slang missing from the dictionary (`шо`). Aim for 99%, not 100%.
- **No network, no clipboard, nothing written to disk.** This is stated in the README; keep it true.
- **SwiftPM + Command Line Tools only, no Xcode project.** `build.sh` wraps the binary into a `.app` with `Info.plist` (`LSUIElement`).
- **Swift 5 language mode,** to avoid Swift 6 strict-concurrency friction with the C event-tap callback.
- **Signed with the self-signed cert "MegaSwitcher Dev"** (old name, kept on purpose), so macOS keeps the permissions across rebuilds. Bundle ID: `local.mega-layout-switcher`.

## Commands
- Build: `./build.sh`. Run: `open build/MegaLayoutSwitcher.app` (never run the binary directly, or the terminal gets the permissions).
- Install: `cp -R build/MegaLayoutSwitcher.app /Applications/`
- Tests: `./test.sh`. It wraps `swift test` with the Swift Testing framework path that Command Line Tools need. The tests use the real installed layouts and spellchecker, serialized on the main actor.
- Demo GIF: `uv run --with pillow python docs/make_demo_gif.py docs/demo.gif` (a rendered Slack-like mockup, not a screen recording).

## Ideas / not done
- Launch at login (SMAppService), remember the Enabled toggle.
- Ghostty and the other terminals are excluded only by the list in `Switcher.swift`.
- Letter n-gram scoring for words the dictionary doesn't know.
