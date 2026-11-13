#!/bin/sh
set -eu
cd "$(dirname "$0")"

app="$PWD/dist/BeijingClock.app"
mkdir -p "$app/Contents/MacOS"
xcrun swiftc BeijingClock/BeijingClockApp.swift \
    -parse-as-library -O -whole-module-optimization \
    -swift-version 5 -target arm64-apple-macosx13.0 \
    -sdk "$(xcrun --show-sdk-path)" \
    -framework SwiftUI -framework AppKit \
    -o "$app/Contents/MacOS/BeijingClock"
cp BeijingClock/Info.plist "$app/Contents/Info.plist"
printf 'APPL????' > "$app/Contents/PkgInfo"
codesign --force --sign - "$app"
codesign --verify --deep --strict "$app"
printf 'Built: %s\n' "$app"
