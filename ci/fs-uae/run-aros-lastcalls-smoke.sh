#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/aros-lastcalls}"
SYSTEM_DIR="build/fs-uae/aros-system"
NATIVE_DIR="build/qualification/native"
mkdir -p "$OUT_DIR"

if [[ ! -f "$NATIVE_DIR/LastCallsTrace" ]]; then
  echo "ERROR: native LastCallsTrace binary missing; run ci/build-native.sh first" >&2
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
logs_dir="$tool_dir/logs"
rm -rf "$tool_dir"
mkdir -p "$logs_dir"
cp "$NATIVE_DIR/LastCallsTrace" "$tool_dir/LastCalls"

# COUNT=3 with more than three login events deliberately fills the retention
# buffer from node 1 before node 2 is scanned. The newer node-2 event must
# displace the oldest retained event; the older late-scanned node-2 event must
# not displace any of the newest three.
cat > "$logs_dir/node1logfile" <<'EOF'
23:00 09/08-26 Login: Old One (local)
23:30 09/08-26 Login: Per Ousdal (local)
00:20 10/08-26 Login: Alice Example (telnet)
EOF
cat > "$logs_dir/node2logfile" <<'EOF'
22:00 09/08-26 Login: Too Old (local)
00:10 10/08-26 Login: Bob User (local)
EOF

cp "$startup" "$startup.abbstools-original"
cat > "$startup" <<'EOF'
SYS:C/Echo "ABBSTOOLS_GUEST_STARTED=1" >SYS:abbstools-lastcalls-stage-started.txt
SYS:ABBSToolsTest/LastCalls SYS:ABBSToolsTest/logs/node 3 2 >SYS:abbstools-lastcalls-output.txt
SYS:C/Echo $RC >SYS:abbstools-lastcalls-rc.txt
SYS:C/Echo "ABBSTOOLS_LASTCALLS_DONE=1" >SYS:abbstools-lastcalls-stage-done.txt
SYS:C/Execute SYS:S/Startup-Sequence.abbstools-original
EOF

rm -f "$aros_root"/abbstools-lastcalls-*.txt

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true

set +e
timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae.log" 2>&1
fs_rc=$?
set -e

started=0
done_stage=0
[[ -f "$aros_root/abbstools-lastcalls-stage-started.txt" ]] && started=1
[[ -f "$aros_root/abbstools-lastcalls-stage-done.txt" ]] && done_stage=1

read_rc() {
  local path="$1"
  [[ -f "$path" ]] && tr -d '\r\n ' < "$path" || true
}

output="$aros_root/abbstools-lastcalls-output.txt"
rc="$(read_rc "$aros_root/abbstools-lastcalls-rc.txt")"

status=FAIL
observation=guest_tool_failure
if [[ "$started" == 1 && "$done_stage" == 1 && "$rc" == "0" && -f "$output" ]] \
   && tr -d '\r' < "$output" | grep -q '^LOGS_FOUND=2$' \
   && tr -d '\r' < "$output" | grep -q '^CALLERS=3$' \
   && tr -d '\r' < "$output" | grep -q '^CALLER INDEX=1 NODE=1 DATE=09/08-26 TIME=23:30 MODE=local USER=Per Ousdal$' \
   && tr -d '\r' < "$output" | grep -q '^CALLER INDEX=2 NODE=2 DATE=10/08-26 TIME=00:10 MODE=local USER=Bob User$' \
   && tr -d '\r' < "$output" | grep -q '^CALLER INDEX=3 NODE=1 DATE=10/08-26 TIME=00:20 MODE=telnet USER=Alice Example$' \
   && ! tr -d '\r' < "$output" | grep -q 'USER=Old One$' \
   && ! tr -d '\r' < "$output" | grep -q 'USER=Too Old$'; then
  status=PASS
  observation=guest_executed_lastcalls_full_buffer_retention_fixture
elif [[ "$started" != 1 ]]; then
  observation=guest_startup_not_reached
elif [[ "$done_stage" != 1 ]]; then
  observation=guest_stopped_in_lastcalls
elif [[ "$rc" != "0" ]]; then
  observation=lastcalls_unexpected_rc
else
  observation=lastcalls_contract_mismatch
fi

{
  echo "STATUS=$status"
  echo "GATE=M3_1_AROS_LASTCALLS"
  echo "MODEL=A1200"
  echo "KICKSTART=internal"
  echo "FS_UAE_EXIT=$fs_rc"
  echo "FIXTURE_PATH_MODE=direct-prefix"
  echo "STAGE_STARTED=$started"
  echo "STAGE_DONE=$done_stage"
  echo "LASTCALLS_RC=$rc"
  echo "OBSERVATION=$observation"
  [[ -f "$output" ]] && tr -d '\r' < "$output" | sed 's/^/OUTPUT=/'
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
