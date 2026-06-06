#!/bin/bash
# Exports the app from an .xcarchive, packages a DMG, notarizes and staples it.
#
# Usage: scripts/notarize.sh <path-to-.xcarchive>
# Env: APPLE_ID, APPLE_APP_PASSWORD, DEVELOPMENT_TEAM
#
# Requires a Developer ID Application certificate in the keychain.
set -euo pipefail

ARCHIVE="${1:?Usage: notarize.sh <archive>}"
OUT="build"
APP_NAME="SpaceMonger"
mkdir -p "$OUT"

# 1. Export a Developer ID-signed app.
cat > "$OUT/ExportOptions.plist" <<PLIST
<?xml version="1.0" encoding="UTF-8"?>
<!DOCTYPE plist PUBLIC "-//Apple//DTD PLIST 1.0//EN" "http://www.apple.com/DTDs/PropertyList-1.0.dtd">
<plist version="1.0">
<dict>
  <key>method</key><string>developer-id</string>
  <key>teamID</key><string>${DEVELOPMENT_TEAM}</string>
  <key>signingStyle</key><string>manual</string>
</dict>
</plist>
PLIST

xcodebuild -exportArchive \
  -archivePath "$ARCHIVE" \
  -exportPath "$OUT/export" \
  -exportOptionsPlist "$OUT/ExportOptions.plist"

APP="$OUT/export/$APP_NAME.app"

# 2. Build a DMG.
DMG="$OUT/$APP_NAME.dmg"
rm -f "$DMG"
hdiutil create -volname "$APP_NAME" -srcfolder "$APP" -ov -format UDZO "$DMG"

# 3. Notarize and staple.
xcrun notarytool submit "$DMG" \
  --apple-id "$APPLE_ID" \
  --password "$APPLE_APP_PASSWORD" \
  --team-id "$DEVELOPMENT_TEAM" \
  --wait

xcrun stapler staple "$DMG"
echo "Done: $DMG"
