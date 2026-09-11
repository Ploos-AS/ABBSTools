#!/usr/bin/env bash
set -euo pipefail

AROS_TARGET="amiga-m68k-boot-iso"
# Verified by the current SourceForge file index: this exact artifact exists
# under nightly2/20260904/Binaries and is the m68k boot ISO we need.
# Pin it for reproducible qualification. Callers may override date/archive/URL.
AROS_BUILD_DATE="${AROS_BUILD_DATE:-20260904}"
AROS_ARCHIVE="${AROS_ARCHIVE:-AROS-${AROS_BUILD_DATE}-${AROS_TARGET}.zip}"
OUT_DIR="${1:-build/fs-uae/aros-system}"

mkdir -p "$OUT_DIR"

if [[ -s "$OUT_DIR/system.iso" && -s "$OUT_DIR/source.txt" && -s "$OUT_DIR/archive.sha256" ]]; then
  echo "CACHE_HIT=$OUT_DIR/system.iso" >&2
  echo "$OUT_DIR/system.iso"
  exit 0
fi

archive="$OUT_DIR/$AROS_ARCHIVE"

if [[ -n "${AROS_URL:-}" ]]; then
  candidates=("$AROS_URL")
else
  candidates=(
    "https://sourceforge.net/projects/aros/files/nightly2/${AROS_BUILD_DATE}/Binaries/${AROS_ARCHIVE}/download"
    "https://downloads.sourceforge.net/project/aros/nightly2/${AROS_BUILD_DATE}/Binaries/${AROS_ARCHIVE}"
  )
fi

resolved_url=""
rm -f "$archive"
for candidate in "${candidates[@]}"; do
  echo "AROS_DOWNLOAD_ATTEMPT=$candidate" >&2
  if curl --fail --location --retry 2 --retry-all-errors --retry-delay 2 \
      --connect-timeout 15 --max-time 300 \
      "$candidate" -o "$archive"; then
    resolved_url="$candidate"
    break
  fi
  rm -f "$archive"
done

if [[ -z "$resolved_url" || ! -s "$archive" ]]; then
  echo "ERROR: unable to download verified AROS artifact $AROS_ARCHIVE" >&2
  exit 1
fi

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
  "$AROS_TARGET" "$AROS_BUILD_DATE" "$AROS_ARCHIVE" "$resolved_url" "$OUT_DIR/system.iso" \
  > "$OUT_DIR/source.txt"

echo "$OUT_DIR/system.iso"
