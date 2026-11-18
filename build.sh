#!/usr/bin/env bash
set -euo pipefail
cd "$(dirname "$0")"

[ -f .env ] && source .env
SIGN_IDENTITY="${SIGN_IDENTITY:-MegaSwitcher Dev}"
APP=build/MegaLayoutSwitcher.app

swift build -c release

rm -rf "$APP"
mkdir -p "$APP/Contents/MacOS" "$APP/Contents/Resources"
cp .build/release/MegaLayoutSwitcher "$APP/Contents/MacOS/"
cp Info.plist "$APP/Contents/"
cp assets/AppIcon.icns "$APP/Contents/Resources/"

# No -v: an untrusted self-signed cert isn't listed as "valid", but codesign uses it fine.
if security find-identity -p codesigning | grep -q "\"$SIGN_IDENTITY\""; then
    codesign --force --sign "$SIGN_IDENTITY" "$APP"
else
    echo "⚠️  Certificate \"$SIGN_IDENTITY\" not found. Signing ad-hoc."
    echo "⚠️  macOS will forget Accessibility/Input Monitoring after every rebuild."
    codesign --force --sign - "$APP"
fi

echo "Built $APP — run: open $APP"
