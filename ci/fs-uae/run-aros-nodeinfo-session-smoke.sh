#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/aros-nodeinfo-session}"
SYSTEM_DIR="build/fs-uae/aros-system"
NATIVE_DIR="build/qualification/native"
mkdir -p "$OUT_DIR"

if [[ ! -f "$NATIVE_DIR/NodeInfo" ]]; then
  echo "ERROR: native NodeInfo binary missing; run ci/build-native.sh first" >&2
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
abbs_dir="$tool_dir/ABBS"
rm -rf "$tool_dir"
mkdir -p "$abbs_dir"
cp "$NATIVE_DIR/NodeInfo" "$tool_dir/NodeInfo"
cp tests/fixtures/node_active.log "$tool_dir/node_active.log"
cp tests/fixtures/node_idle.log "$tool_dir/node_idle.log"
cp tests/fixtures/node_unknown.log "$tool_dir/node_unknown.log"

cp "$startup" "$startup.abbstools-original"
cat > "$startup" <<'EOF'
SYS:C/Echo "ABBSTOOLS_GUEST_STARTED=1" >SYS:abbstools-nodeinfo-stage-started.txt
SYS:C/Assign ABBS: SYS:ABBSToolsTest/ABBS
SYS:C/Echo "ABBSTOOLS_ASSIGN_DONE=1" >SYS:abbstools-nodeinfo-stage-assign.txt
SYS:C/Copy SYS:ABBSToolsTest/node_active.log ABBS:node1logfile QUIET
SYS:C/Echo "ABBSTOOLS_ACTIVE_COPY_DONE=1" >SYS:abbstools-nodeinfo-stage-active-copy.txt
SYS:ABBSToolsTest/NodeInfo 1 >SYS:abbstools-nodeinfo-active.txt
SYS:C/Echo $RC >SYS:abbstools-nodeinfo-active-rc.txt
SYS:C/Echo "ABBSTOOLS_ACTIVE_DONE=1" >SYS:abbstools-nodeinfo-stage-active-done.txt
SYS:C/Copy SYS:ABBSToolsTest/node_idle.log ABBS:node1logfile QUIET
SYS:C/Echo "ABBSTOOLS_IDLE_COPY_DONE=1" >SYS:abbstools-nodeinfo-stage-idle-copy.txt
SYS:ABBSToolsTest/NodeInfo 1 >SYS:abbstools-nodeinfo-idle.txt
SYS:C/Echo $RC >SYS:abbstools-nodeinfo-idle-rc.txt
SYS:C/Echo "ABBSTOOLS_IDLE_DONE=1" >SYS:abbstools-nodeinfo-stage-idle-done.txt
SYS:C/Copy SYS:ABBSToolsTest/node_unknown.log ABBS:node1logfile QUIET
SYS:C/Echo "ABBSTOOLS_UNKNOWN_COPY_DONE=1" >SYS:abbstools-nodeinfo-stage-unknown-copy.txt
SYS:ABBSToolsTest/NodeInfo 1 >SYS:abbstools-nodeinfo-unknown.txt
SYS:C/Echo $RC >SYS:abbstools-nodeinfo-unknown-rc.txt
SYS:C/Echo "ABBSTOOLS_UNKNOWN_DONE=1" >SYS:abbstools-nodeinfo-stage-unknown-done.txt
SYS:C/Echo "ABBSTOOLS_AFTER_NODEINFO_SESSION=1" >SYS:abbstools-nodeinfo-stage-after.txt
SYS:C/Execute SYS:S/Startup-Sequence.abbstools-original
EOF

rm -f "$aros_root"/abbstools-nodeinfo-*.txt

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true

set +e
timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae.log" 2>&1
fs_rc=$?
set -e

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

active_rc="$(read_rc "$active_rc_file")"
idle_rc="$(read_rc "$idle_rc_file")"
unknown_rc="$(read_rc "$unknown_rc_file")"

started="$(has_stage started)"
assign_done="$(has_stage assign)"
active_copy_done="$(has_stage active-copy)"
active_done="$(has_stage active-done)"
idle_copy_done="$(has_stage idle-copy)"
idle_done="$(has_stage idle-done)"
unknown_copy_done="$(has_stage unknown-copy)"
unknown_done="$(has_stage unknown-done)"
after_done="$(has_stage after)"

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
  observation=guest_executed_nodeinfo_session_fixtures
elif [[ "$started" != 1 ]]; then
  observation=guest_startup_not_reached
elif [[ "$assign_done" != 1 ]]; then
  observation=guest_stopped_at_assign
elif [[ "$active_copy_done" != 1 ]]; then
  observation=guest_stopped_at_active_copy
elif [[ "$active_done" != 1 ]]; then
  observation=guest_stopped_in_active_nodeinfo
elif [[ "$idle_copy_done" != 1 ]]; then
  observation=guest_stopped_at_idle_copy
elif [[ "$idle_done" != 1 ]]; then
  observation=guest_stopped_in_idle_nodeinfo
elif [[ "$unknown_copy_done" != 1 ]]; then
  observation=guest_stopped_at_unknown_copy
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
  echo "STAGE_STARTED=$started"
  echo "STAGE_ASSIGN=$assign_done"
  echo "STAGE_ACTIVE_COPY=$active_copy_done"
  echo "STAGE_ACTIVE_DONE=$active_done"
  echo "STAGE_IDLE_COPY=$idle_copy_done"
  echo "STAGE_IDLE_DONE=$idle_done"
  echo "STAGE_UNKNOWN_COPY=$unknown_copy_done"
  echo "STAGE_UNKNOWN_DONE=$unknown_done"
  echo "STAGE_AFTER=$after_done"
  echo "ACTIVE_RC=$active_rc"
  echo "IDLE_RC=$idle_rc"
  echo "UNKNOWN_RC=$unknown_rc"
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
