#!/usr/bin/env bash
# MIT License
#
# Copyright (c) 2026 Daniel Berg <mail@roosta.sh>
#
# Permission is hereby granted, free of charge, to any person obtaining a copy of
# this software and associated documentation files (the "Software"), to deal in
# the Software without restriction, including without limitation the rights to
# use, copy, modify, merge, publish, distribute, sublicense, and/or sell copies
# of the Software, and to permit persons to whom the Software is furnished to do
# so, subject to the following conditions:
#
# The above copyright notice and this permission notice shall be included in all
# copies or substantial portions of the Software.
#
# THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
# IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
# FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
# AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
# LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
# OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE
# SOFTWARE.
#
# Drafted Feb 2026 based on LLM suggestion (claude-4.5-sonnet)
# reviewed and edited by Daniel Berg <mail@roosta.sh>

set -euo pipefail

USAGE="Usage: $0 <palette.gpl> [output_dir] [tile_size]"
PALETTE_FILE="${1:?${USAGE}}"
OUTPUT_DIR="${2:-./assets}"
TILE_SIZE="${3:-100}"
OUTPUT_NAME="$(basename "${PALETTE_FILE%.gpl}")"
OUTPUT_FILE="${OUTPUT_DIR}/${OUTPUT_NAME}_swatch.jpg"

mkdir -p "$OUTPUT_DIR"

# Build ImageMagick argument list by parsing the GPL palette file.
# The -size flag is set once and applies to all subsequent xc: images.
args=(-size "${TILE_SIZE}x${TILE_SIZE}")
count=0

while IFS= read -r line; do
  # Skip empty lines
  [[ -z "$line" ]] && continue
  # Skip comment lines
  [[ "$line" =~ ^[[:space:]]*# ]] && continue
  # Skip GPL header lines
  [[ "$line" =~ ^GIMP[[:space:]]Palette ]] && continue
  [[ "$line" =~ ^Name: ]] && continue
  [[ "$line" =~ ^Columns: ]] && continue

    # Parse: r g b [optional color name]
    read -r r g b _name <<< "$line"

    # Validate that r, g, b are integers within the 0-255 sRGB range
    if [[ "$r" =~ ^[0-9]+$ ]] && [[ "$g" =~ ^[0-9]+$ ]] && [[ "$b" =~ ^[0-9]+$ ]] \
      && (( r <= 255 && g <= 255 && b <= 255 )); then
      args+=("xc:rgb(${r},${g},${b})")
        (( ++count ))
    fi
  done < "$PALETTE_FILE"

  if (( count == 0 )); then
    echo "Error: no valid colors found in '${PALETTE_FILE}'" >&2
    exit 1
  fi

  echo "Rendering ${count} color tiles at ${TILE_SIZE}x${TILE_SIZE}px..."

  magick "${args[@]}" +append "$OUTPUT_FILE"

  echo "Saved: ${OUTPUT_FILE}"

