#!/usr/bin/env bash
# Build the JKDApp slides as a single self-contained-ish HTML file.
# Notes:
#   - --html          allows raw HTML (the <video> tag on the Motion Capture slide)
#   - --allow-local-files is REQUIRED, or Marp strips the local img/*.png and the mp4
set -euo pipefail

cd "$(dirname "$0")"

npx --yes @marp-team/marp-cli@latest \
  --html \
  --allow-local-files \
  slides.md \
  -o slides.html

echo "✅ slides.html generated ($(du -h slides.html | cut -f1))"
echo "   Open it in a browser (the slides are in the same folder as the assets)."
echo "   To share: keep slides.html + img/ + mocap_predemo.mp4 together."