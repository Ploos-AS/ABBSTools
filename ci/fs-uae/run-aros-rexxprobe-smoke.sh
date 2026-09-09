#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/aros-rexxprobe}"
SYSTEM_DIR="build/fs-uae/aros-system"
NATIVE_DIR="build/qualification/native"
mkdir -p "$OUT_DIR"

if [[ ! -f "$NATIVE_DIR/RexxProbe" ]]; then
  echo "ERROR: native RexxProbe binary missing; run ci/build-native.sh first" >&2
  exit 1
fi

iso="$(bash ci/fs-uae/fetch-aros-system.sh "$SYSTEM_DIR" | tail -n 1)"
root_extract="$OUT_DIR/system-root"
rm -rf "$root_extract"
mkdir -p "$root_extract"
7z x -y -o"$root_extract" "$iso" >/dev/null

startup="$(find "$root_extract" -type f -ipath '*/s/startup-sequence' -print -quit)"
if [[ -z "$startup" ]]; then
  echo "ERROR: AROS system ISO does not contain S/Startup-Sequence" >&2
  exit 1
fi

aros_root="$(dirname "$(dirname "$startup")")"
tool_dir="$aros_root/ABBSToolsTest"
rm -rf "$tool_dir"
mkdir -p "$tool_dir"
cp "$NATIVE_DIR/RexxProbe" "$tool_dir/RexxProbe"

cp "$startup" "$startup.abbstools-original"
cat > "$startup" <<'EOF'
SYS:C/Echo "ABBSTOOLS_GUEST_STARTED=1" >SYS:abbstools-started.txt
SYS:ABBSToolsTest/RexxProbe ABBSTOOLS.PORT.THAT.DOES.NOT.EXIST PING >SYS:abbstools-rexxprobe.txt
SYS:C/Echo $RC >SYS:abbstools-rexxprobe-rc.txt
SYS:C/Echo "ABBSTOOLS_AFTER_REXXPROBE=1" >SYS:abbstools-after-rexxprobe.txt
SYS:C/Execute SYS:S/Startup-Sequence.abbstools-original
EOF

rm -f "$aros_root"/abbstools-*.txt

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true

set +e
timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae.log" 2>&1
fs_rc=$?
set -e

out="$aros_root/abbstools-rexxprobe.txt"
rcfile="$aros_root/abbstools-rexxprobe-rc.txt"
after="$aros_root/abbstools-after-rexxprobe.txt"
started="$aros_root/abbstools-started.txt"

status=FAIL
observation=guest_tool_failure
rc=""
if [[ -f "$rcfile" ]]; then
  rc="$(tr -d '\r\n ' < "$rcfile")"
fi

if [[ -f "$started" && -f "$after" && -f "$out" && -f "$rcfile" ]] \
   && grep -q '^PORT_NOT_FOUND' "$out" \
   && [[ "$rc" == "10" ]]; then
  status=PASS
  observation=guest_executed_rexxprobe_missing_port_path
fi

{
  echo "STATUS=$status"
  echo "GATE=M1_2_AROS_REXXPROBE_MISSING_PORT"
  echo "MODEL=A1200"
  echo "KICKSTART=internal"
  echo "FS_UAE_EXIT=$fs_rc"
  echo "REXXPROBE_GUEST_RC=$rc"
  echo "OBSERVATION=$observation"
  if [[ -f "$out" ]]; then
    tr -d '\r' < "$out" | sed 's/^/GUEST_REXXPROBE=/'
  fi
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
