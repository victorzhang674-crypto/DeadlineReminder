#!/bin/bash
set -euo pipefail
cd "$(dirname "$0")"
TEMP_DIR=$(mktemp -d "${TMPDIR:-/tmp}/deadline-reminder.XXXXXX")
trap 'rm -rf "$TEMP_DIR"' EXIT
APP="$TEMP_DIR/Deadline Reminder.app"
mkdir -p "$APP/Contents/MacOS"
swiftc -parse-as-library -O Sources/DeadlineReminder.swift -o "$APP/Contents/MacOS/Deadline Reminder"
cat > "$APP/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0"><dict>
<key>CFBundleName</key><string>Deadline Reminder</string>
<key>CFBundleDisplayName</key><string>Deadline Reminder</string>
<key>CFBundleIdentifier</key><string>local.deadline-reminder.app</string>
<key>CFBundleVersion</key><string>1</string>
<key>CFBundleShortVersionString</key><string>1.0</string>
<key>CFBundleExecutable</key><string>Deadline Reminder</string>
<key>CFBundlePackageType</key><string>APPL</string>
<key>NSHighResolutionCapable</key><true/>
</dict></plist>
PLIST
codesign --force --deep --sign - "$APP"
mkdir -p build
rm -rf "build/Deadline Reminder.app"
ditto "$APP" "build/Deadline Reminder.app"
echo "Built build/Deadline Reminder.app"
