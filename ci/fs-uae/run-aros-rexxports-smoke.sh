#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/aros-rexxports}"
SYSTEM_DIR="build/fs-uae/aros-system"
NATIVE_DIR="build/qualification/native"
mkdir -p "$OUT_DIR"

if [[ ! -f "$NATIVE_DIR/RexxPorts" ]]; then
  echo "ERROR: native RexxPorts binary missing; run ci/build-native.sh first" >&2
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
cp "$NATIVE_DIR/RexxPorts" "$tool_dir/RexxPorts"

cp "$startup" "$startup.abbstools-original"
cat > "$startup" <<'EOF'
SYS:C/Echo "ABBSTOOLS_GUEST_STARTED=1" >SYS:abbstools-started.txt
SYS:ABBSToolsTest/RexxPorts >SYS:abbstools-rexxports.txt
SYS:C/Echo $RC >SYS:abbstools-rexxports-rc.txt
SYS:C/Echo "ABBSTOOLS_AFTER_REXXPORTS=1" >SYS:abbstools-after-rexxports.txt
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

out="$aros_root/abbstools-rexxports.txt"
rcfile="$aros_root/abbstools-rexxports-rc.txt"
after="$aros_root/abbstools-after-rexxports.txt"
started="$aros_root/abbstools-started.txt"

status=FAIL
observation=guest_tool_failure
rc=""
if [[ -f "$rcfile" ]]; then
  rc="$(tr -d '\r\n ' < "$rcfile")"
fi

if [[ -f "$started" && -f "$after" && -f "$out" && -f "$rcfile" ]] \
   && grep -q 'RexxPorts 0.1' "$out" \
   && grep -q 'ABBSTools - Ploos AS' "$out" \
   && grep -q 'Sig Name' "$out" \
   && { [[ "$rc" == "0" ]] || [[ "$rc" == "5" ]]; }; then
  status=PASS
  observation=guest_executed_rexxports
fi

{
  echo "STATUS=$status"
  echo "GATE=M1_1_AROS_REXXPORTS"
  echo "MODEL=A1200"
  echo "KICKSTART=internal"
  echo "FS_UAE_EXIT=$fs_rc"
  echo "REXXPORTS_GUEST_RC=$rc"
  echo "OBSERVATION=$observation"
  if [[ -f "$out" ]]; then
    tr -d '\r' < "$out" | sed 's/^/GUEST_REXXPORTS=/'
  fi
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
