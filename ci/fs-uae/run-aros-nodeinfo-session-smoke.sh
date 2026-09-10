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
SYS:C/Echo "ABBSTOOLS_GUEST_STARTED=1" >SYS:abbstools-nodeinfo-started.txt
SYS:C/Assign ABBS: SYS:ABBSToolsTest/ABBS
SYS:C/Copy SYS:ABBSToolsTest/node_active.log ABBS:node1logfile QUIET
SYS:ABBSToolsTest/NodeInfo 1 >SYS:abbstools-nodeinfo-active.txt
SYS:C/Echo $RC >SYS:abbstools-nodeinfo-active-rc.txt
SYS:C/Copy SYS:ABBSToolsTest/node_idle.log ABBS:node1logfile QUIET
SYS:ABBSToolsTest/NodeInfo 1 >SYS:abbstools-nodeinfo-idle.txt
SYS:C/Echo $RC >SYS:abbstools-nodeinfo-idle-rc.txt
SYS:C/Copy SYS:ABBSToolsTest/node_unknown.log ABBS:node1logfile QUIET
SYS:ABBSToolsTest/NodeInfo 1 >SYS:abbstools-nodeinfo-unknown.txt
SYS:C/Echo $RC >SYS:abbstools-nodeinfo-unknown-rc.txt
SYS:C/Echo "ABBSTOOLS_AFTER_NODEINFO_SESSION=1" >SYS:abbstools-nodeinfo-after.txt
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
started="$aros_root/abbstools-nodeinfo-started.txt"
after="$aros_root/abbstools-nodeinfo-after.txt"

read_rc() {
  local f="$1"
  if [[ -f "$f" ]]; then tr -d '\r\n ' < "$f"; fi
}

active_rc="$(read_rc "$active_rc_file")"
idle_rc="$(read_rc "$idle_rc_file")"
unknown_rc="$(read_rc "$unknown_rc_file")"

status=FAIL
observation=guest_tool_failure
if [[ -f "$started" && -f "$after" && -f "$active" && -f "$idle" && -f "$unknown" ]] \
   && grep -q '^SESSION=ACTIVE$' "$active" \
   && grep -q '^USER=Test User$' "$active" \
   && grep -q '^SESSION=IDLE$' "$idle" \
   && grep -q '^USER=$' "$idle" \
   && grep -q '^SESSION=UNKNOWN$' "$unknown" \
   && [[ "$active_rc" == "0" ]] \
   && [[ "$idle_rc" == "0" ]] \
   && [[ "$unknown_rc" == "0" ]]; then
  status=PASS
  observation=guest_executed_nodeinfo_session_fixtures
fi

{
  echo "STATUS=$status"
  echo "GATE=M1_3C_AROS_NODEINFO_SESSION"
  echo "MODEL=A1200"
  echo "KICKSTART=internal"
  echo "FS_UAE_EXIT=$fs_rc"
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
