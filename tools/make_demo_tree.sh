#!/bin/bash
#
# Creates a neutral, privacy-free demo folder with dummy files of varied types
# and sizes — ideal for taking consistent SpaceMonger screenshots without
# exposing any personal data.
#
# Usage:
#   tools/make_demo_tree.sh [target-folder]
#   SCALE=2 tools/make_demo_tree.sh ~/Desktop/"SpaceMonger Demo"
#
# • Default target: ~/Desktop/SpaceMonger Demo
# • SCALE multiplies every file size (default 1). SCALE=1 is ~450 MB.
# • Files are real (allocated) so the app measures them like real data.
#   To remove afterwards: just drag the folder to the Trash.

set -euo pipefail

TARGET="${1:-$HOME/Desktop/SpaceMonger Demo}"
SCALE="${SCALE:-1}"

if ! command -v mkfile >/dev/null 2>&1; then
  echo "This script needs macOS's 'mkfile'. Run it on a Mac." >&2
  exit 1
fi

if [ -e "$TARGET" ]; then
  echo "Refusing to overwrite existing path: $TARGET" >&2
  echo "Pass a different folder, or remove it first." >&2
  exit 1
fi

echo "Creating demo tree at: $TARGET  (SCALE=$SCALE)"
mkdir -p "$TARGET"

# mb <megabytes> <relative/path> — make a real, allocated file.
mb() {
  local size_mb=$(( $1 * SCALE ))
  [ "$size_mb" -lt 1 ] && size_mb=1
  local path="$TARGET/$2"
  mkdir -p "$(dirname "$path")"
  mkfile "${size_mb}m" "$path"
}

# kb <kilobytes> <relative/path>
kb() {
  local path="$TARGET/$2"
  mkdir -p "$(dirname "$path")"
  mkfile "${1}k" "$path"
}

echo "• Videos"
mb 180 "Videos/Holiday.mov"
mb 70  "Videos/Tutorial.mp4"
mb 32  "Videos/Drone clip.mp4"
mb 18  "Videos/Screen recording.mov"

echo "• Photos"
for y in 2022 2023 2024; do
  for i in $(seq 1 14); do
    mb 3 "Photos/$y/IMG_$(printf '%04d' "$i").jpg"
  done
done
for i in $(seq 1 6); do
  mb 22 "Photos/RAW/DSC_$(printf '%04d' "$i").raw"
done

echo "• Music"
for album in "Ambient Sessions" "Live Set"; do
  for t in $(seq 1 10); do
    mb 7 "Music/$album/$(printf '%02d' "$t") Track.mp3"
  done
done

echo "• Documents"
for i in $(seq 1 8); do mb 2 "Documents/Reports/Report $i.pdf"; done
for i in $(seq 1 5); do mb 1 "Documents/Spreadsheets/Budget $i.xlsx"; done
for i in $(seq 1 12); do kb 40 "Documents/Notes/Note $i.md"; done

echo "• Design files"
mb 55 "Projects/Design/Poster.psd"
mb 38 "Projects/Design/Banner.psd"
mb 12 "Projects/Design/Logo.sketch"

echo "• A web project (with node_modules for the exclusions demo)"
mb 4 "Projects/WebApp/dist/bundle.js"
mb 1 "Projects/WebApp/src/app.js"
for i in $(seq 1 220); do
  kb 8 "Projects/WebApp/node_modules/pkg-$(printf '%03d' "$i")/index.js"
done

echo "• Downloads"
mb 130 "Downloads/Installer.dmg"
mb 60  "Downloads/Archive.zip"
mb 24  "Downloads/dataset.csv"

echo "• Caches"
for i in $(seq 1 4); do mb 15 "Library/Caches/com.example.app/cache-$i.bin"; done

echo "• A sample app bundle (shows package handling)"
mkdir -p "$TARGET/Applications/DemoApp.app/Contents/MacOS"
cat > "$TARGET/Applications/DemoApp.app/Contents/Info.plist" <<'PLIST'
<?xml version="1.0" encoding="UTF-8"?>
<plist version="1.0"><dict>
  <key>CFBundleName</key><string>DemoApp</string>
  <key>CFBundleIdentifier</key><string>com.example.DemoApp</string>
</dict></plist>
PLIST
mb 28 "Applications/DemoApp.app/Contents/MacOS/DemoApp"
mb 6  "Applications/DemoApp.app/Contents/Resources/Assets.car"

echo ""
echo "Done. Total size:"
du -sh "$TARGET" 2>/dev/null || true
echo ""
echo "Now scan it in SpaceMonger (Scan a Folder… or drag the folder onto the start screen)."
echo "Tip: add 'node_modules' under Settings ▸ Exclusions to demo that feature."
