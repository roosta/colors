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
#
# Generate swatches for palette files in `./palette` directory
#
# It will generate the files in `./assets`, and update the readme under the
# "Palette files" heading.
#
# Usage: run from repo root `./scripts/thumbnails.sh`
set -euo pipefail

PALETTES_DIR="./palettes"
OUTPUT_DIR="./assets"
README="./README.md"
TILE_SIZE="${1:-50}"

mkdir -p "$OUTPUT_DIR"

palette_names=()
palette_files=()

for palette in "${PALETTES_DIR}"/*.gpl; do
  filename="$(basename "$palette")"
  stem="${filename%.gpl}"
  output="${OUTPUT_DIR}/${stem}.jpg"

  # Use the Name: field from the palette header, fall back to the filename stem
  palette_name="$(grep -m1 '^Name:' "$palette" \
    | sed 's/^Name:[[:space:]]*//' \
    | sed 's/[[:space:]]*$//')"
  [[ -z "$palette_name" ]] && palette_name="$stem"

  # Build ImageMagick args by parsing colour entries
  args=(-size "${TILE_SIZE}x${TILE_SIZE}")
  while IFS= read -r line; do
    [[ -z "$line" ]]                         && continue
    [[ "$line" =~ ^[[:space:]]*# ]]          && continue
    [[ "$line" =~ ^GIMP[[:space:]]Palette ]] && continue
    [[ "$line" =~ ^Name: ]]                  && continue
    [[ "$line" =~ ^Columns: ]]               && continue

    read -r r g b _name <<< "$line"

    if [[ "$r" =~ ^[0-9]+$ ]] && [[ "$g" =~ ^[0-9]+$ ]] && [[ "$b" =~ ^[0-9]+$ ]] \
      && (( r <= 255 && g <= 255 && b <= 255 )); then
      args+=("xc:rgb(${r},${g},${b})")
    fi
  done < "$palette"

  if (( ${#args[@]} <= 2 )); then
    echo "Warning: no valid colors found in '${palette}', skipping." >&2
    continue
  fi

  echo "Rendering ${filename} -> ${output}"
  magick "${args[@]}" +append "$output"

  palette_names+=("$palette_name")
  palette_files+=("$filename")
done

# ---------------------------------------------------------------------------
# Rebuild the ## Palette files section in the README
# ---------------------------------------------------------------------------
tmp_section="$(mktemp)"

{
  printf '## Palette files\n\n'
  for i in "${!palette_files[@]}"; do
    name="${palette_names[$i]}"
    file="${palette_files[$i]}"
    stem="${file%.gpl}"
    printf '### [%s](./palettes/%s)\n\n' "$name" "$file"
    printf '![%s swatch](./assets/%s.jpg)\n\n' "$name" "$stem"
  done
} > "$tmp_section"

awk '
  /^## Palette files/ {
    in_section = 1
    while ((getline line < "'"$tmp_section"'") > 0) print line
    next
  }
  in_section && /^## / { in_section = 0 }
  !in_section { print }
' "$README" > "${README}.tmp" && mv "${README}.tmp" "$README"

rm -f "$tmp_section"

echo "README.md updated."
echo "Done."

