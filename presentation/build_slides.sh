#!/usr/bin/env bash
# Build the JKDApp slides as PDF.
#   - --allow-local-files is REQUIRED: without it, Marp CLI strips the local
#     img/*.png and the mp4 from the output for security reasons.
#   - --html renders the raw <video> tag on the Motion Capture slide
#     (otherwise it would appear as literal text).
set -euo pipefail

cd "$(dirname "$0")"

npx --yes @marp-team/marp-cli@latest \
  --allow-local-files \
  --html \
  --pdf \
  slides.md \
  -o slides.pdf

echo "✅ slides.pdf generated ($(du -h slides.pdf | cut -f1))"