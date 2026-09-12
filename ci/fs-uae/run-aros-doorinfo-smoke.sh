#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/aros-doorinfo}"
SYSTEM_DIR="build/fs-uae/aros-system"
NATIVE_DIR="build/qualification/native"
mkdir -p "$OUT_DIR"

if [[ ! -f "$NATIVE_DIR/DoorInfo" ]]; then
  echo "ERROR: native DoorInfo binary missing; run ci/build-native.sh first" >&2
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
cp "$NATIVE_DIR/DoorInfo" "$tool_dir/DoorInfo"
printf 'door fixture\n' > "$tool_dir/door.bin"

cp "$startup" "$startup.abbstools-original"
cat > "$startup" <<'EOF'
SYS:C/Echo "ABBSTOOLS_GUEST_STARTED=1" >SYS:abbstools-doorinfo-stage-started.txt
SYS:ABBSToolsTest/DoorInfo SYS:ABBSToolsTest/door.bin >SYS:abbstools-doorinfo-present.txt
SYS:C/Echo $RC >SYS:abbstools-doorinfo-present-rc.txt
SYS:ABBSToolsTest/DoorInfo SYS:ABBSToolsTest/missing-door.bin >SYS:abbstools-doorinfo-missing.txt
SYS:C/Echo $RC >SYS:abbstools-doorinfo-missing-rc.txt
SYS:C/Echo "ABBSTOOLS_DOORINFO_DONE=1" >SYS:abbstools-doorinfo-stage-done.txt
SYS:C/Execute SYS:S/Startup-Sequence.abbstools-original
EOF

rm -f "$aros_root"/abbstools-doorinfo-*.txt

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true

set +e
timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae.log" 2>&1
fs_rc=$?
set -e

started=0
done_stage=0
[[ -f "$aros_root/abbstools-doorinfo-stage-started.txt" ]] && started=1
[[ -f "$aros_root/abbstools-doorinfo-stage-done.txt" ]] && done_stage=1

read_rc() {
  local path="$1"
  [[ -f "$path" ]] && tr -d '\r\n ' < "$path" || true
}

present_out="$aros_root/abbstools-doorinfo-present.txt"
missing_out="$aros_root/abbstools-doorinfo-missing.txt"
present_rc="$(read_rc "$aros_root/abbstools-doorinfo-present-rc.txt")"
missing_rc="$(read_rc "$aros_root/abbstools-doorinfo-missing-rc.txt")"

status=FAIL
observation=guest_tool_failure
if [[ "$started" == 1 && "$done_stage" == 1 && "$present_rc" == "0" && "$missing_rc" == "5" ]] \
   && [[ -f "$present_out" && -f "$missing_out" ]] \
   && tr -d '\r' < "$present_out" | grep -q '^STATUS=OK$' \
   && tr -d '\r' < "$present_out" | grep -q '^PRESENT=YES$' \
   && tr -d '\r' < "$present_out" | grep -q '^TYPE=FILE$' \
   && tr -d '\r' < "$missing_out" | grep -q '^STATUS=WARN$' \
   && tr -d '\r' < "$missing_out" | grep -q '^PRESENT=NO$' \
   && tr -d '\r' < "$missing_out" | grep -q '^REASON=PATH_NOT_PRESENT$'; then
  status=PASS
  observation=guest_executed_doorinfo_present_and_missing_fixtures
elif [[ "$started" != 1 ]]; then
  observation=guest_startup_not_reached
elif [[ "$done_stage" != 1 ]]; then
  observation=guest_stopped_in_doorinfo
elif [[ "$present_rc" != "0" || "$missing_rc" != "5" ]]; then
  observation=doorinfo_unexpected_rc
else
  observation=doorinfo_contract_mismatch
fi

{
  echo "STATUS=$status"
  echo "GATE=M4_1_AROS_DOORINFO"
  echo "MODEL=A1200"
  echo "KICKSTART=internal"
  echo "FS_UAE_EXIT=$fs_rc"
  echo "FIXTURE_PRESENT=SYS:ABBSToolsTest/door.bin"
  echo "FIXTURE_MISSING=SYS:ABBSToolsTest/missing-door.bin"
  echo "STAGE_STARTED=$started"
  echo "STAGE_DONE=$done_stage"
  echo "PRESENT_RC=$present_rc"
  echo "MISSING_RC=$missing_rc"
  echo "OBSERVATION=$observation"
  [[ -f "$present_out" ]] && tr -d '\r' < "$present_out" | sed 's/^/PRESENT_OUTPUT=/'
  [[ -f "$missing_out" ]] && tr -d '\r' < "$missing_out" | sed 's/^/MISSING_OUTPUT=/'
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
