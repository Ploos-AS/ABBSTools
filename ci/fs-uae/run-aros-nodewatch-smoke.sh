#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/aros-nodewatch}"
SYSTEM_DIR="build/fs-uae/aros-system"
NATIVE_DIR="build/qualification/native"
mkdir -p "$OUT_DIR"

if [[ ! -f "$NATIVE_DIR/NodeWatchTrace" ]]; then
  echo "ERROR: traced native NodeWatch binary missing; run ci/build-native.sh first" >&2
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
active_dir="$tool_dir/ABBS-active"
rm -rf "$tool_dir"
mkdir -p "$active_dir"
cp "$NATIVE_DIR/NodeWatchTrace" "$tool_dir/NodeWatch"
cp tests/fixtures/node_active.log "$active_dir/node1logfile"

cp "$startup" "$startup.abbstools-original"
cat > "$startup" <<'EOF'
SYS:C/Echo "ABBSTOOLS_GUEST_STARTED=1" >SYS:abbstools-nodewatch-stage-started.txt
SYS:ABBSToolsTest/NodeWatch 1 1 2 SYS:ABBSToolsTest/ABBS-active/node1logfile >SYS:abbstools-nodewatch-output.txt
SYS:C/Echo $RC >SYS:abbstools-nodewatch-rc.txt
SYS:C/Echo "ABBSTOOLS_NODEWATCH_DONE=1" >SYS:abbstools-nodewatch-stage-done.txt
SYS:C/Execute SYS:S/Startup-Sequence.abbstools-original
EOF

rm -f "$aros_root"/abbstools-nodewatch-*.txt

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true

set +e
timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae.log" 2>&1
fs_rc=$?
set -e

output="$aros_root/abbstools-nodewatch-output.txt"
rc_file="$aros_root/abbstools-nodewatch-rc.txt"
started=0
done_stage=0
[[ -f "$aros_root/abbstools-nodewatch-stage-started.txt" ]] && started=1
[[ -f "$aros_root/abbstools-nodewatch-stage-done.txt" ]] && done_stage=1
rc=""
if [[ -f "$rc_file" ]]; then
  rc="$(tr -d '\r\n ' < "$rc_file")"
fi

status=FAIL
observation=guest_tool_failure
if [[ "$started" == 1 && "$done_stage" == 1 && -f "$output" && "$rc" == "0" ]] \
   && tr -d '\r' < "$output" | grep -q '^SAMPLE=1 NODE=1 PRESENT=0 STATE=OFFLINE LOG_PRESENT=1 SESSION=ACTIVE USER=Test User$' \
   && tr -d '\r' < "$output" | grep -q '^SAMPLE=2 NODE=1 PRESENT=0 STATE=OFFLINE LOG_PRESENT=1 SESSION=ACTIVE USER=Test User$' \
   && [[ "$(tr -d '\r' < "$output" | grep -c '^SAMPLE=')" == "2" ]]; then
  status=PASS
  observation=guest_executed_two_nodewatch_samples
elif [[ "$started" != 1 ]]; then
  observation=guest_startup_not_reached
elif [[ "$done_stage" != 1 ]]; then
  observation=guest_stopped_in_nodewatch
elif [[ ! -f "$output" ]]; then
  observation=nodewatch_output_missing
elif [[ "$rc" != "0" ]]; then
  observation=nodewatch_nonzero_rc
else
  observation=nodewatch_contract_mismatch
fi

{
  echo "STATUS=$status"
  echo "GATE=M2_1_AROS_NODEWATCH"
  echo "MODEL=A1200"
  echo "KICKSTART=internal"
  echo "FS_UAE_EXIT=$fs_rc"
  echo "FIXTURE_PATH_MODE=direct"
  echo "COUNT=2"
  echo "INTERVAL=1"
  echo "STAGE_STARTED=$started"
  echo "STAGE_DONE=$done_stage"
  echo "NODEWATCH_RC=$rc"
  echo "OBSERVATION=$observation"
  if [[ -f "$output" ]]; then
    tr -d '\r' < "$output" | sed 's/^/OUTPUT=/'
  fi
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
