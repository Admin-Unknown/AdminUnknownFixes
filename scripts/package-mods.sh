#!/usr/bin/env bash
# Build Factorio release zips for AdminUnknownFixes (repo root) and its companion mods,
# each of which lives in a folder of its own and is copied whole.
# Also copies the companion zips into repo stubs/ for direct-download artifacts.
# Usage (from repo root): ./scripts/package-mods.sh
# Optional: OUT_DIR=build ./scripts/package-mods.sh   CLEAN=1 ./scripts/package-mods.sh

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
ROOT="$(cd "$SCRIPT_DIR/.." && pwd)"
OUT_DIR="${OUT_DIR:-dist}"
DIST="$ROOT/$OUT_DIR"

COMPANION_FOLDERS=(PyCoalTBaA-stub extend-guard-stub)

json_field() {
  local file="$1" field="$2"
  if command -v python3 >/dev/null 2>&1; then
    python3 -c "import json,sys; print(json.load(open(sys.argv[1],encoding='utf-8'))[sys.argv[2]])" "$file" "$field"
  elif command -v jq >/dev/null 2>&1; then
    jq -r ".$field" "$file"
  else
    echo "Need python3 or jq to read $file" >&2
    exit 1
  fi
}

stage_main() {
  local inner="$1"
  mkdir -p "$inner"
  local f
  for f in control.lua data.lua data-updates.lua data-final-fixes.lua settings.lua settings-final-fixes.lua info.json changelog.txt thumbnail.png; do
    if [[ -f "$ROOT/$f" ]]; then
      cp -f "$ROOT/$f" "$inner/"
    fi
  done
  local d
  for d in functions graphics locale migrations prototypes; do
    if [[ -d "$ROOT/$d" ]]; then
      cp -R "$ROOT/$d" "$inner/"
    fi
  done
}

stage_companion() {
  local folder="$1" inner="$2"
  mkdir -p "$inner"
  shopt -s dotglob nullglob
  for p in "$ROOT/$folder"/*; do
    cp -R "$p" "$inner/"
  done
  shopt -u dotglob nullglob
}

zip_one() {
  local parent="$1" folder_name="$2" zip_path="$3"
  ( cd "$parent" && zip -qr "$zip_path" "$folder_name" )
}

MAIN_NAME="$(json_field "$ROOT/info.json" name)"
MAIN_VER="$(json_field "$ROOT/info.json" version)"
MAIN_INNER="${MAIN_NAME}_${MAIN_VER}"

STAGING="$(mktemp -d "${TMPDIR:-/tmp}/auf-pack.XXXXXX")"
cleanup() { rm -rf "$STAGING"; }
trap cleanup EXIT

if [[ "${CLEAN:-}" == "1" ]] && [[ -d "$DIST" ]]; then
  rm -rf "$DIST"
fi
mkdir -p "$DIST"

stage_main "$STAGING/$MAIN_INNER"
MAIN_ZIP="$DIST/${MAIN_NAME}_${MAIN_VER}.zip"
rm -f "$MAIN_ZIP"
zip_one "$STAGING" "$MAIN_INNER" "$MAIN_ZIP"

echo "Wrote:"
echo "  $MAIN_ZIP"

STUBS="$ROOT/stubs"
mkdir -p "$STUBS"

for folder in "${COMPANION_FOLDERS[@]}"; do
  name="$(json_field "$ROOT/$folder/info.json" name)"
  version="$(json_field "$ROOT/$folder/info.json" version)"
  inner="${name}_${version}"
  stage_companion "$folder" "$STAGING/$inner"
  zip_path="$DIST/${inner}.zip"
  rm -f "$zip_path"
  zip_one "$STAGING" "$inner" "$zip_path"
  echo "  $zip_path"
  cp -f "$zip_path" "$STUBS/"
done

echo "Copied companion zips to:"
echo "  $STUBS"
