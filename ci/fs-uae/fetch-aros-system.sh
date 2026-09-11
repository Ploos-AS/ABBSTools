#!/usr/bin/env bash
set -euo pipefail

AROS_TARGET="amiga-m68k-boot-iso"
# SourceForge currently publishes this verified m68k boot ISO under nightly2/20260901/Binaries.
# Keep it pinned for reproducible qualification; callers may override all three values explicitly.
AROS_BUILD_DATE="${AROS_BUILD_DATE:-20260901}"
AROS_ARCHIVE="${AROS_ARCHIVE:-AROS-${AROS_BUILD_DATE}-${AROS_TARGET}.zip}"
AROS_URL="${AROS_URL:-https://sourceforge.net/projects/aros/files/nightly2/${AROS_BUILD_DATE}/Binaries/${AROS_ARCHIVE}/download}"
OUT_DIR="${1:-build/fs-uae/aros-system}"

mkdir -p "$OUT_DIR"

if [[ -s "$OUT_DIR/system.iso" && -s "$OUT_DIR/source.txt" && -s "$OUT_DIR/archive.sha256" ]]; then
  echo "CACHE_HIT=$OUT_DIR/system.iso" >&2
  echo "$OUT_DIR/system.iso"
  exit 0
fi

archive="$OUT_DIR/$AROS_ARCHIVE"
curl --fail --location --retry 3 --retry-delay 2 \
  --connect-timeout 15 --max-time 300 \
  "$AROS_URL" -o "$archive"
sha256sum "$archive" | tee "$OUT_DIR/archive.sha256"

rm -rf "$OUT_DIR/archive-extracted"
mkdir -p "$OUT_DIR/archive-extracted"
case "$AROS_ARCHIVE" in
  *.lha|*.LHA) lha xw="$OUT_DIR/archive-extracted" "$archive" >/dev/null ;;
  *.zip|*.ZIP) unzip -q "$archive" -d "$OUT_DIR/archive-extracted" ;;
  *) echo "ERROR: unsupported AROS archive format: $AROS_ARCHIVE" >&2; exit 1 ;;
esac

iso="$(find "$OUT_DIR/archive-extracted" -type f \( -iname '*.iso' -o -iname '*.ISO' \) -print -quit)"
if [[ -z "$iso" ]]; then
  echo "ERROR: no ISO found in $AROS_ARCHIVE" >&2
  exit 1
fi

cp "$iso" "$OUT_DIR/system.iso"
printf 'AROS_TARGET=%s\nAROS_BUILD_DATE=%s\nAROS_ARCHIVE=%s\nAROS_URL=%s\nISO=%s\n' \
  "$AROS_TARGET" "$AROS_BUILD_DATE" "$AROS_ARCHIVE" "$AROS_URL" "$OUT_DIR/system.iso" \
  > "$OUT_DIR/source.txt"

echo "$OUT_DIR/system.iso"
