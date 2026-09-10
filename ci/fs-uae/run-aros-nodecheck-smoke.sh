#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/aros-nodecheck}"
SYSTEM_DIR="build/fs-uae/aros-system"
NATIVE_DIR="build/qualification/native"
mkdir -p "$OUT_DIR"

if [[ ! -f "$NATIVE_DIR/NodeCheckTrace" ]]; then
  echo "ERROR: traced native NodeCheck binary missing; run ci/build-native.sh first" >&2
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
unknown_dir="$tool_dir/ABBS-unknown"
missing_dir="$tool_dir/ABBS-missing"
rm -rf "$tool_dir"
mkdir -p "$active_dir" "$unknown_dir" "$missing_dir"
cp "$NATIVE_DIR/NodeCheckTrace" "$tool_dir/NodeCheck"
cp tests/fixtures/node_active.log "$active_dir/node1logfile"
cp tests/fixtures/node_unknown.log "$unknown_dir/node1logfile"

cp "$startup" "$startup.abbstools-original"
cat > "$startup" <<'EOF'
SYS:C/Echo "ABBSTOOLS_GUEST_STARTED=1" >SYS:abbstools-nodecheck-stage-started.txt
SYS:ABBSToolsTest/NodeCheck 1 SYS:ABBSToolsTest/ABBS-active/node1logfile >SYS:abbstools-nodecheck-active-output.txt
SYS:C/Echo $RC >SYS:abbstools-nodecheck-active-rc.txt
SYS:ABBSToolsTest/NodeCheck 1 SYS:ABBSToolsTest/ABBS-unknown/node1logfile >SYS:abbstools-nodecheck-unknown-output.txt
SYS:C/Echo $RC >SYS:abbstools-nodecheck-unknown-rc.txt
SYS:ABBSToolsTest/NodeCheck 1 SYS:ABBSToolsTest/ABBS-missing/node1logfile >SYS:abbstools-nodecheck-missing-output.txt
SYS:C/Echo $RC >SYS:abbstools-nodecheck-missing-rc.txt
SYS:C/Echo "ABBSTOOLS_NODECHECK_DONE=1" >SYS:abbstools-nodecheck-stage-done.txt
SYS:C/Execute SYS:S/Startup-Sequence.abbstools-original
EOF

rm -f "$aros_root"/abbstools-nodecheck-*.txt

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true

set +e
timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae.log" 2>&1
fs_rc=$?
set -e

started=0
done_stage=0
[[ -f "$aros_root/abbstools-nodecheck-stage-started.txt" ]] && started=1
[[ -f "$aros_root/abbstools-nodecheck-stage-done.txt" ]] && done_stage=1

read_rc() {
  local path="$1"
  if [[ -f "$path" ]]; then
    tr -d '\r\n ' < "$path"
  fi
}

active_output="$aros_root/abbstools-nodecheck-active-output.txt"
unknown_output="$aros_root/abbstools-nodecheck-unknown-output.txt"
missing_output="$aros_root/abbstools-nodecheck-missing-output.txt"
active_rc="$(read_rc "$aros_root/abbstools-nodecheck-active-rc.txt")"
unknown_rc="$(read_rc "$aros_root/abbstools-nodecheck-unknown-rc.txt")"
missing_rc="$(read_rc "$aros_root/abbstools-nodecheck-missing-rc.txt")"

status=FAIL
observation=guest_tool_failure
if [[ "$started" == 1 && "$done_stage" == 1 \
   && -f "$active_output" && -f "$unknown_output" && -f "$missing_output" \
   && "$active_rc" == "5" && "$unknown_rc" == "5" && "$missing_rc" == "5" ]] \
   && tr -d '\r' < "$active_output" | grep -q '^NODE=1 HEALTH=WARN REASON=PORT_NOT_PRESENT PRESENT=0 STATE=OFFLINE LOG_PRESENT=1 SESSION=ACTIVE USER=Test User$' \
   && tr -d '\r' < "$unknown_output" | grep -q '^NODE=1 HEALTH=WARN REASON=PORT_NOT_PRESENT PRESENT=0 STATE=OFFLINE LOG_PRESENT=1 SESSION=UNKNOWN USER=$' \
   && tr -d '\r' < "$missing_output" | grep -q '^NODE=1 HEALTH=WARN REASON=PORT_NOT_PRESENT PRESENT=0 STATE=OFFLINE LOG_PRESENT=0 SESSION=UNKNOWN USER=$'; then
  status=PASS
  observation=guest_executed_nodecheck_fixture_matrix
elif [[ "$started" != 1 ]]; then
  observation=guest_startup_not_reached
elif [[ "$done_stage" != 1 ]]; then
  observation=guest_stopped_in_nodecheck
elif [[ "$active_rc" != "5" || "$unknown_rc" != "5" || "$missing_rc" != "5" ]]; then
  observation=nodecheck_unexpected_rc
else
  observation=nodecheck_contract_mismatch
fi

{
  echo "STATUS=$status"
  echo "GATE=M2_2_AROS_NODECHECK"
  echo "MODEL=A1200"
  echo "KICKSTART=internal"
  echo "FS_UAE_EXIT=$fs_rc"
  echo "FIXTURE_PATH_MODE=direct"
  echo "STAGE_STARTED=$started"
  echo "STAGE_DONE=$done_stage"
  echo "ACTIVE_RC=$active_rc"
  echo "UNKNOWN_RC=$unknown_rc"
  echo "MISSING_RC=$missing_rc"
  echo "OBSERVATION=$observation"
  [[ -f "$active_output" ]] && tr -d '\r' < "$active_output" | sed 's/^/ACTIVE_OUTPUT=/'
  [[ -f "$unknown_output" ]] && tr -d '\r' < "$unknown_output" | sed 's/^/UNKNOWN_OUTPUT=/'
  [[ -f "$missing_output" ]] && tr -d '\r' < "$missing_output" | sed 's/^/MISSING_OUTPUT=/'
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
