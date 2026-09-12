#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/aros-metrics}"
SYSTEM_DIR="build/fs-uae/aros-system"
NATIVE_DIR="build/qualification/native"
mkdir -p "$OUT_DIR"

if [[ ! -f "$NATIVE_DIR/MetricsTrace" ]]; then
  echo "ERROR: traced native Metrics binary missing; run ci/build-native.sh first" >&2
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
rm -rf "$tool_dir"
mkdir -p "$active_dir" "$unknown_dir"
cp "$NATIVE_DIR/MetricsTrace" "$tool_dir/Metrics"
cp tests/fixtures/node_active.log "$active_dir/node1logfile"
cp tests/fixtures/node_unknown.log "$unknown_dir/node1logfile"

cp "$startup" "$startup.abbstools-original"
cat > "$startup" <<'EOF'
SYS:C/Echo "ABBSTOOLS_GUEST_STARTED=1" >SYS:abbstools-metrics-stage-started.txt
SYS:ABBSToolsTest/Metrics 1 SYS:ABBSToolsTest/ABBS-active/node1logfile >SYS:abbstools-metrics-active-output.txt
SYS:C/Echo $RC >SYS:abbstools-metrics-active-rc.txt
SYS:ABBSToolsTest/Metrics 1 SYS:ABBSToolsTest/ABBS-unknown/node1logfile >SYS:abbstools-metrics-unknown-output.txt
SYS:C/Echo $RC >SYS:abbstools-metrics-unknown-rc.txt
SYS:C/Echo "ABBSTOOLS_METRICS_DONE=1" >SYS:abbstools-metrics-stage-done.txt
SYS:C/Execute SYS:S/Startup-Sequence.abbstools-original
EOF

rm -f "$aros_root"/abbstools-metrics-*.txt

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true

set +e
timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae.log" 2>&1
fs_rc=$?
set -e

started=0
done_stage=0
[[ -f "$aros_root/abbstools-metrics-stage-started.txt" ]] && started=1
[[ -f "$aros_root/abbstools-metrics-stage-done.txt" ]] && done_stage=1

read_rc() {
  local path="$1"
  if [[ -f "$path" ]]; then
    tr -d '\r\n ' < "$path"
  fi
}

active_output="$aros_root/abbstools-metrics-active-output.txt"
unknown_output="$aros_root/abbstools-metrics-unknown-output.txt"
active_rc="$(read_rc "$aros_root/abbstools-metrics-active-rc.txt")"
unknown_rc="$(read_rc "$aros_root/abbstools-metrics-unknown-rc.txt")"

status=FAIL
observation=guest_tool_failure
if [[ "$started" == 1 && "$done_stage" == 1 \
   && -f "$active_output" && -f "$unknown_output" \
   && "$active_rc" == "0" && "$unknown_rc" == "0" ]] \
   && tr -d '\r' < "$active_output" | grep -q '^abbs_node_present{node="1"} 0$' \
   && tr -d '\r' < "$active_output" | grep -q '^abbs_node_log_present{node="1"} 1$' \
   && tr -d '\r' < "$active_output" | grep -q '^abbs_node_session_active{node="1"} 1$' \
   && tr -d '\r' < "$active_output" | grep -q '^abbs_node_session_known{node="1"} 1$' \
   && tr -d '\r' < "$unknown_output" | grep -q '^abbs_node_present{node="1"} 0$' \
   && tr -d '\r' < "$unknown_output" | grep -q '^abbs_node_log_present{node="1"} 1$' \
   && tr -d '\r' < "$unknown_output" | grep -q '^abbs_node_session_active{node="1"} 0$' \
   && tr -d '\r' < "$unknown_output" | grep -q '^abbs_node_session_known{node="1"} 0$'; then
  status=PASS
  observation=guest_executed_metrics_snapshot_fixtures
elif [[ "$started" != 1 ]]; then
  observation=guest_startup_not_reached
elif [[ "$done_stage" != 1 ]]; then
  observation=guest_stopped_in_metrics
elif [[ "$active_rc" != "0" || "$unknown_rc" != "0" ]]; then
  observation=metrics_unexpected_rc
else
  observation=metrics_contract_mismatch
fi

{
  echo "STATUS=$status"
  echo "GATE=M6_1_AROS_METRICS"
  echo "MODEL=A1200"
  echo "KICKSTART=internal"
  echo "FS_UAE_EXIT=$fs_rc"
  echo "FIXTURE_PATH_MODE=direct"
  echo "STAGE_STARTED=$started"
  echo "STAGE_DONE=$done_stage"
  echo "ACTIVE_RC=$active_rc"
  echo "UNKNOWN_RC=$unknown_rc"
  echo "OBSERVATION=$observation"
  [[ -f "$active_output" ]] && tr -d '\r' < "$active_output" | sed 's/^/ACTIVE_OUTPUT=/'
  [[ -f "$unknown_output" ]] && tr -d '\r' < "$unknown_output" | sed 's/^/UNKNOWN_OUTPUT=/'
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
