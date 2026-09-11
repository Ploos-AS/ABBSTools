#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/aros-confinfo}"
SYSTEM_DIR="build/fs-uae/aros-system"
NATIVE_DIR="build/qualification/native"
mkdir -p "$OUT_DIR"

if [[ ! -f "$NATIVE_DIR/ConfInfoTrace" ]]; then
  echo "ERROR: native ConfInfoTrace binary missing; run ci/build-native.sh first" >&2
  exit 1
fi

iso="$(bash ci/fs-uae/fetch-aros-system.sh "$SYSTEM_DIR" | tail -n 1)"
root_extract="$OUT_DIR/system-root"
rm -rf "$root_extract"
mkdir -p "$root_extract"
7z x -y -o"$root_extract" "$iso" >/dev/null

startup="$(find "$root_extract" -type f -ipath '*/s/startup-sequence' -print -quit)"
[[ -n "$startup" ]] || { echo "ERROR: AROS system ISO lacks S/Startup-Sequence" >&2; exit 1; }
aros_root="$(dirname "$(dirname "$startup")")"
tool_dir="$aros_root/ABBSToolsTest"
mkdir -p "$tool_dir"
cp "$NATIVE_DIR/ConfInfoTrace" "$tool_dir/ConfInfo"

cp "$startup" "$startup.abbstools-original"
cat > "$startup" <<'EOF'
SYS:C/Echo "ABBSTOOLS_GUEST_STARTED=1" >SYS:abbstools-confinfo-stage-started.txt
SYS:ABBSToolsTest/ConfInfo 1 "General" 1 123 1 0 50 0 8 >SYS:abbstools-confinfo-output.txt
SYS:C/Echo $RC >SYS:abbstools-confinfo-rc.txt
SYS:C/Echo "ABBSTOOLS_CONFINFO_DONE=1" >SYS:abbstools-confinfo-stage-done.txt
SYS:C/Execute SYS:S/Startup-Sequence.abbstools-original
EOF

rm -f "$aros_root"/abbstools-confinfo-*.txt
config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true
set +e
timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae.log" 2>&1
fs_rc=$?
set -e

started=0; done_stage=0
[[ -f "$aros_root/abbstools-confinfo-stage-started.txt" ]] && started=1
[[ -f "$aros_root/abbstools-confinfo-stage-done.txt" ]] && done_stage=1
rc=""
[[ -f "$aros_root/abbstools-confinfo-rc.txt" ]] && rc="$(tr -d '\r\n ' < "$aros_root/abbstools-confinfo-rc.txt")"
output="$aros_root/abbstools-confinfo-output.txt"
status=FAIL; observation=guest_tool_failure
if [[ "$started" == 1 && "$done_stage" == 1 && "$rc" == 0 && -f "$output" ]] \
   && tr -d '\r' < "$output" | grep -q '^STATUS=OK$' \
   && tr -d '\r' < "$output" | grep -q '^CONFERENCE=1$' \
   && tr -d '\r' < "$output" | grep -q '^NAME=General$' \
   && tr -d '\r' < "$output" | grep -q '^ORDER=1$' \
   && tr -d '\r' < "$output" | grep -q '^DEFAULT_MSG=123$' \
   && tr -d '\r' < "$output" | grep -q '^FIRST_MSG=1$' \
   && tr -d '\r' < "$output" | grep -q '^MAX_SCAN=50$' \
   && tr -d '\r' < "$output" | grep -q '^MAX_CONFERENCES=8$'; then
  status=PASS; observation=guest_executed_confinfo_trace_fixture
fi

{
  echo "STATUS=$status"
  echo "GATE=M3_4_AROS_CONFINFO"
  echo "MODEL=A1200"
  echo "KICKSTART=internal"
  echo "FS_UAE_EXIT=$fs_rc"
  echo "CONFINFO_RC=$rc"
  echo "OBSERVATION=$observation"
  [[ -f "$output" ]] && tr -d '\r' < "$output" | sed 's/^/OUTPUT=/'
} | tee "$OUT_DIR/result.txt"
[[ "$status" == PASS ]]
