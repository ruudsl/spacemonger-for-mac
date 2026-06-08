#!/bin/bash
# Optimize the screenshots to WebP (and smaller PNG) for faster loading.
# Uses cwebp if available, else macOS `sips` for WebP. Run from repo root:
#   web/optimize-images.sh
set -euo pipefail
cd "$(dirname "$0")/shots"
for png in *.png; do
  base="${png%.png}"
  if command -v cwebp >/dev/null 2>&1; then
    cwebp -q 82 -resize 1600 0 "$png" -o "$base.webp"
  elif command -v sips >/dev/null 2>&1; then
    # sips can resize PNG; WebP export needs macOS 13+
    sips -s format webp -Z 1600 "$png" --out "$base.webp" >/dev/null 2>&1 || \
      echo "Install cwebp (brew install webp) for best results."
  else
    echo "Install cwebp: brew install webp"; exit 1
  fi
  echo "  -> $base.webp"
done
echo "Done. The page already references these via <picture>."
