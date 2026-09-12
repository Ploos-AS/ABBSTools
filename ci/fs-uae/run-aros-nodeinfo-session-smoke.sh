#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/aros-nodeinfo-session}"
SYSTEM_DIR="build/fs-uae/aros-system"
NATIVE_DIR="build/qualification/native"
mkdir -p "$OUT_DIR"

if [[ ! -f "$NATIVE_DIR/NodeInfoTrace" ]]; then
  echo "ERROR: traced native NodeInfo binary missing; run ci/build-native.sh first" >&2
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
idle_dir="$tool_dir/ABBS-idle"
unknown_dir="$tool_dir/ABBS-unknown"
rm -rf "$tool_dir"
mkdir -p "$active_dir" "$idle_dir" "$unknown_dir"
cp "$NATIVE_DIR/NodeInfoTrace" "$tool_dir/NodeInfo"
cp tests/fixtures/node_active.log "$active_dir/node1logfile"
cp tests/fixtures/node_idle.log "$idle_dir/node1logfile"
cp tests/fixtures/node_unknown.log "$unknown_dir/node1logfile"

cp "$startup" "$startup.abbstools-original"
cat > "$startup" <<'EOF'
SYS:C/Echo "ABBSTOOLS_GUEST_STARTED=1" >SYS:abbstools-nodeinfo-stage-started.txt
SYS:C/Echo "ABBSTOOLS_ACTIVE_PATH_READY=1" >SYS:abbstools-nodeinfo-stage-active-path.txt
SYS:ABBSToolsTest/NodeInfo 1 SYS:ABBSToolsTest/ABBS-active/node1logfile >SYS:abbstools-nodeinfo-active.txt
SYS:C/Echo $RC >SYS:abbstools-nodeinfo-active-rc.txt
SYS:C/Echo "ABBSTOOLS_ACTIVE_DONE=1" >SYS:abbstools-nodeinfo-stage-active-done.txt
SYS:C/Echo "ABBSTOOLS_IDLE_PATH_READY=1" >SYS:abbstools-nodeinfo-stage-idle-path.txt
SYS:ABBSToolsTest/NodeInfo 1 SYS:ABBSToolsTest/ABBS-idle/node1logfile >SYS:abbstools-nodeinfo-idle.txt
SYS:C/Echo $RC >SYS:abbstools-nodeinfo-idle-rc.txt
SYS:C/Echo "ABBSTOOLS_IDLE_DONE=1" >SYS:abbstools-nodeinfo-stage-idle-done.txt
SYS:C/Echo "ABBSTOOLS_UNKNOWN_PATH_READY=1" >SYS:abbstools-nodeinfo-stage-unknown-path.txt
SYS:ABBSToolsTest/NodeInfo 1 SYS:ABBSToolsTest/ABBS-unknown/node1logfile >SYS:abbstools-nodeinfo-unknown.txt
SYS:C/Echo $RC >SYS:abbstools-nodeinfo-unknown-rc.txt
SYS:C/Echo "ABBSTOOLS_UNKNOWN_DONE=1" >SYS:abbstools-nodeinfo-stage-unknown-done.txt
SYS:C/Echo "ABBSTOOLS_AFTER_NODEINFO_SESSION=1" >SYS:abbstools-nodeinfo-stage-after.txt
SYS:C/Execute SYS:S/Startup-Sequence.abbstools-original
EOF

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true

clear_guest_markers() {
  rm -f "$aros_root"/abbstools-nodeinfo-*.txt
}

fs_rc=0
boot_attempt=0
boot_started=0
for attempt in 1 2; do
  boot_attempt="$attempt"
  clear_guest_markers
  set +e
  timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae-attempt-${attempt}.log" 2>&1
  fs_rc=$?
  set -e
  cp "$OUT_DIR/fs-uae-attempt-${attempt}.log" "$OUT_DIR/fs-uae.log"
  if [[ -f "$aros_root/abbstools-nodeinfo-stage-started.txt" ]]; then
    boot_started=1
    break
  fi
  echo "WARN: NodeInfo guest startup marker missing after attempt $attempt; retrying once" >&2
done

active="$aros_root/abbstools-nodeinfo-active.txt"
idle="$aros_root/abbstools-nodeinfo-idle.txt"
unknown="$aros_root/abbstools-nodeinfo-unknown.txt"
active_rc_file="$aros_root/abbstools-nodeinfo-active-rc.txt"
idle_rc_file="$aros_root/abbstools-nodeinfo-idle-rc.txt"
unknown_rc_file="$aros_root/abbstools-nodeinfo-unknown-rc.txt"

read_rc() {
  local f="$1"
  if [[ -f "$f" ]]; then tr -d '\r\n ' < "$f"; fi
}

has_stage() {
  local name="$1"
  if [[ -f "$aros_root/abbstools-nodeinfo-stage-$name.txt" ]]; then
    echo 1
  else
    echo 0
  fi
}

has_internal() {
  local name="$1"
  if [[ -f "$aros_root/abbstools-nodeinfo-internal-$name.txt" ]]; then
    echo 1
  else
    echo 0
  fi
}

active_rc="$(read_rc "$active_rc_file")"
idle_rc="$(read_rc "$idle_rc_file")"
unknown_rc="$(read_rc "$unknown_rc_file")"

started="$(has_stage started)"
active_path_ready="$(has_stage active-path)"
active_done="$(has_stage active-done)"
idle_path_ready="$(has_stage idle-path)"
idle_done="$(has_stage idle-done)"
unknown_path_ready="$(has_stage unknown-path)"
unknown_done="$(has_stage unknown-done)"
after_done="$(has_stage after)"

internal_stages=(query-enter paths-built before-forbid after-forbid after-findport after-permit before-session before-open after-open before-read after-read before-close after-close query-exit)

status=FAIL
observation=guest_tool_failure
if [[ "$started" == 1 && "$after_done" == 1 && -f "$active" && -f "$idle" && -f "$unknown" ]] \
   && tr -d '\r' < "$active" | grep -q '^SESSION=ACTIVE$' \
   && tr -d '\r' < "$active" | grep -q '^USER=Test User$' \
   && tr -d '\r' < "$idle" | grep -q '^SESSION=IDLE$' \
   && tr -d '\r' < "$idle" | grep -q '^USER=$' \
   && tr -d '\r' < "$unknown" | grep -q '^SESSION=UNKNOWN$' \
   && [[ "$active_rc" == "0" ]] \
   && [[ "$idle_rc" == "0" ]] \
   && [[ "$unknown_rc" == "0" ]]; then
  status=PASS
  observation=guest_executed_nodeinfo_session_fixtures_direct_paths
elif [[ "$started" != 1 ]]; then
  observation=guest_startup_not_reached_after_retry
elif [[ "$active_path_ready" != 1 ]]; then
  observation=guest_stopped_before_active_path
elif [[ "$active_done" != 1 ]]; then
  observation=guest_stopped_in_active_nodeinfo
elif [[ "$idle_path_ready" != 1 ]]; then
  observation=guest_stopped_before_idle_path
elif [[ "$idle_done" != 1 ]]; then
  observation=guest_stopped_in_idle_nodeinfo
elif [[ "$unknown_path_ready" != 1 ]]; then
  observation=guest_stopped_before_unknown_path
elif [[ "$unknown_done" != 1 ]]; then
  observation=guest_stopped_in_unknown_nodeinfo
elif [[ "$after_done" != 1 ]]; then
  observation=guest_stopped_after_unknown_nodeinfo
else
  observation=guest_completed_but_contract_mismatch
fi

{
  echo "STATUS=$status"
  echo "GATE=M1_3C_AROS_NODEINFO_SESSION"
  echo "MODEL=A1200"
  echo "KICKSTART=internal"
  echo "FS_UAE_EXIT=$fs_rc"
  echo "FIXTURE_PATH_MODE=direct"
  echo "BOOT_ATTEMPT=$boot_attempt"
  echo "BOOT_STARTED=$boot_started"
  echo "STAGE_STARTED=$started"
  echo "STAGE_ACTIVE_PATH=$active_path_ready"
  echo "STAGE_ACTIVE_DONE=$active_done"
  echo "STAGE_IDLE_PATH=$idle_path_ready"
  echo "STAGE_IDLE_DONE=$idle_done"
  echo "STAGE_UNKNOWN_PATH=$unknown_path_ready"
  echo "STAGE_UNKNOWN_DONE=$unknown_done"
  echo "STAGE_AFTER=$after_done"
  echo "ACTIVE_RC=$active_rc"
  echo "IDLE_RC=$idle_rc"
  echo "UNKNOWN_RC=$unknown_rc"
  for stage in "${internal_stages[@]}"; do
    key="$(printf '%s' "$stage" | tr '[:lower:]-' '[:upper:]_')"
    echo "INTERNAL_${key}=$(has_internal "$stage")"
  done
  echo "OBSERVATION=$observation"
  for pair in ACTIVE:$active IDLE:$idle UNKNOWN:$unknown; do
    label="${pair%%:*}"
    file="${pair#*:}"
    if [[ -f "$file" ]]; then
      tr -d '\r' < "$file" | sed "s/^/${label}=/"
    fi
  done
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
