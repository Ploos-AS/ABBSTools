#!/usr/bin/env bash
set -euo pipefail

AROS_TARGET="amiga-m68k-boot-iso"
AROS_INDEX_URL="${AROS_INDEX_URL:-https://sourceforge.net/projects/aros/files/nightly2/}"
OUT_DIR="${1:-build/fs-uae/aros-system}"

mkdir -p "$OUT_DIR"

if [[ -s "$OUT_DIR/system.iso" && -s "$OUT_DIR/source.txt" && -s "$OUT_DIR/archive.sha256" ]]; then
  echo "CACHE_HIT=$OUT_DIR/system.iso" >&2
  echo "$OUT_DIR/system.iso"
  exit 0
fi

fetch() {
  curl --fail --location --retry 2 --retry-all-errors --retry-delay 2 \
    --connect-timeout 15 --max-time 300 "$@"
}

resolved_url=""
resolved_date=""
resolved_archive=""
archive=""

if [[ -n "${AROS_URL:-}" ]]; then
  resolved_url="$AROS_URL"
  resolved_archive="${AROS_ARCHIVE:-$(basename "${AROS_URL%%\?*}")}" 
  archive="$OUT_DIR/$resolved_archive"
  echo "AROS_DOWNLOAD_ATTEMPT=$resolved_url" >&2
  fetch "$resolved_url" -o "$archive"
else
  index_html="$OUT_DIR/sourceforge-nightly2.html"
  fetch "$AROS_INDEX_URL" -o "$index_html"

  mapfile -t dates < <(
    grep -oE '/projects/aros/files/nightly2/[0-9]{8}/' "$index_html" \
      | sed -E 's#.*/([0-9]{8})/#\1#' \
      | sort -r -u
  )

  if [[ ${#dates[@]} -eq 0 ]]; then
    echo "ERROR: no nightly2 build directories discovered from $AROS_INDEX_URL" >&2
    exit 1
  fi

  for date in "${dates[@]}"; do
    binaries_url="https://sourceforge.net/projects/aros/files/nightly2/${date}/Binaries/"
    binaries_html="$OUT_DIR/sourceforge-${date}-binaries.html"
    echo "AROS_DISCOVERY_ATTEMPT=$binaries_url" >&2
    if ! fetch "$binaries_url" -o "$binaries_html"; then
      continue
    fi

    candidate_archive="$(
      grep -oE "AROS-[0-9]{8}-${AROS_TARGET}\\.(zip|lha|LHA)" "$binaries_html" \
        | head -n 1 || true
    )"
    if [[ -z "$candidate_archive" ]]; then
      continue
    fi

    candidates=(
      "https://sourceforge.net/projects/aros/files/nightly2/${date}/Binaries/${candidate_archive}/download"
      "https://downloads.sourceforge.net/project/aros/nightly2/${date}/Binaries/${candidate_archive}"
    )

    for candidate in "${candidates[@]}"; do
      tmp="$OUT_DIR/${candidate_archive}.part"
      rm -f "$tmp"
      echo "AROS_DOWNLOAD_ATTEMPT=$candidate" >&2
      if fetch "$candidate" -o "$tmp"; then
        case "$candidate_archive" in
          *.zip|*.ZIP)
            if unzip -tq "$tmp" >/dev/null 2>&1; then
              resolved_url="$candidate"
              resolved_date="$date"
              resolved_archive="$candidate_archive"
              archive="$OUT_DIR/$candidate_archive"
              mv "$tmp" "$archive"
              break 2
            fi
            ;;
          *.lha|*.LHA)
            if lha l "$tmp" >/dev/null 2>&1; then
              resolved_url="$candidate"
              resolved_date="$date"
              resolved_archive="$candidate_archive"
              archive="$OUT_DIR/$candidate_archive"
              mv "$tmp" "$archive"
              break 2
            fi
            ;;
        esac
      fi
      rm -f "$tmp"
    done
  done
fi

if [[ -z "$resolved_url" || -z "$archive" || ! -s "$archive" ]]; then
  echo "ERROR: unable to discover and download a valid $AROS_TARGET artifact" >&2
  exit 1
fi

sha256sum "$archive" | tee "$OUT_DIR/archive.sha256"

rm -rf "$OUT_DIR/archive-extracted"
mkdir -p "$OUT_DIR/archive-extracted"
case "$resolved_archive" in
  *.lha|*.LHA) lha xw="$OUT_DIR/archive-extracted" "$archive" >/dev/null ;;
  *.zip|*.ZIP) unzip -q "$archive" -d "$OUT_DIR/archive-extracted" ;;
  *) echo "ERROR: unsupported AROS archive format: $resolved_archive" >&2; exit 1 ;;
esac

iso="$(find "$OUT_DIR/archive-extracted" -type f \( -iname '*.iso' -o -iname '*.ISO' \) -print -quit)"
if [[ -z "$iso" ]]; then
  echo "ERROR: no ISO found in $resolved_archive" >&2
  exit 1
fi

cp "$iso" "$OUT_DIR/system.iso"
printf 'AROS_INDEX_URL=%s\nAROS_TARGET=%s\nAROS_BUILD_DATE=%s\nAROS_ARCHIVE=%s\nAROS_URL=%s\nISO=%s\n' \
  "$AROS_INDEX_URL" "$AROS_TARGET" "$resolved_date" "$resolved_archive" "$resolved_url" "$OUT_DIR/system.iso" \
  > "$OUT_DIR/source.txt"

echo "$OUT_DIR/system.iso"
