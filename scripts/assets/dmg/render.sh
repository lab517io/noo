#!/bin/bash
# Render background.svg to the two PNGs the DMG uses (1x and 2x).
#
# The PNGs are committed, so a build machine needs nothing but tiffutil; run
# this only after editing the SVG.
#
# WebKit does the rendering, through QuickLook: ImageMagick's built-in SVG
# renderer silently drops gradients and filters, which is most of this artwork,
# and rsvg-convert is not something a Mac has by default. qlmanage always
# writes a square thumbnail, so each render is cropped back to shape.
set -euo pipefail

cd "$(dirname "$0")"

command -v magick >/dev/null || { echo "ImageMagick (magick) is required" >&2; exit 1; }

render() {          # render <pixel width> <pixel height> <output>
  local w=$1 h=$2 out=$3 tmp
  tmp=$(mktemp -d)
  qlmanage -t -s "$w" -o "$tmp" background.svg >/dev/null 2>&1
  [ -f "$tmp/background.svg.png" ] || { echo "qlmanage produced no thumbnail" >&2; exit 1; }
  magick "$tmp/background.svg.png" -crop "${w}x${h}+0+0" +repage -strip "$out"
  rm -rf "$tmp"
  echo "  $out ($(magick identify -format '%wx%h' "$out"))"
}

echo "Rendering DMG background..."
render 640 380 background.png
render 1280 760 background@2x.png
