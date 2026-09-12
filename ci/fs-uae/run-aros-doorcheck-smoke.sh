#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/aros-doorcheck}"
SYSTEM_DIR="build/fs-uae/aros-system"
NATIVE_DIR="build/qualification/native"
mkdir -p "$OUT_DIR"

if [[ ! -f "$NATIVE_DIR/DoorCheck" ]]; then
  echo "ERROR: native DoorCheck binary missing; run ci/build-native.sh first" >&2
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
mkdir -p "$tool_dir/DoorDir"
cp "$NATIVE_DIR/DoorCheck" "$tool_dir/DoorCheck"
printf 'door check fixture\n' > "$tool_dir/door.bin"

cp "$startup" "$startup.abbstools-original"
cat > "$startup" <<'EOF'
SYS:C/Echo "ABBSTOOLS_GUEST_STARTED=1" >SYS:abbstools-doorcheck-stage-started.txt
SYS:ABBSToolsTest/DoorCheck SYS:ABBSToolsTest/door.bin FILE >SYS:abbstools-doorcheck-match.txt
SYS:C/Echo $RC >SYS:abbstools-doorcheck-match-rc.txt
SYS:ABBSToolsTest/DoorCheck SYS:ABBSToolsTest/door.bin DIRECTORY >SYS:abbstools-doorcheck-mismatch.txt
SYS:C/Echo $RC >SYS:abbstools-doorcheck-mismatch-rc.txt
SYS:ABBSToolsTest/DoorCheck SYS:ABBSToolsTest/missing-door.bin ANY >SYS:abbstools-doorcheck-missing.txt
SYS:C/Echo $RC >SYS:abbstools-doorcheck-missing-rc.txt
SYS:C/Echo "ABBSTOOLS_DOORCHECK_DONE=1" >SYS:abbstools-doorcheck-stage-done.txt
SYS:C/Execute SYS:S/Startup-Sequence.abbstools-original
EOF

rm -f "$aros_root"/abbstools-doorcheck-*.txt

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true

set +e
timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae.log" 2>&1
fs_rc=$?
set -e

started=0
done_stage=0
[[ -f "$aros_root/abbstools-doorcheck-stage-started.txt" ]] && started=1
[[ -f "$aros_root/abbstools-doorcheck-stage-done.txt" ]] && done_stage=1

read_rc() {
  local path="$1"
  [[ -f "$path" ]] && tr -d '\r\n ' < "$path" || true
}

match_out="$aros_root/abbstools-doorcheck-match.txt"
mismatch_out="$aros_root/abbstools-doorcheck-mismatch.txt"
missing_out="$aros_root/abbstools-doorcheck-missing.txt"
match_rc="$(read_rc "$aros_root/abbstools-doorcheck-match-rc.txt")"
mismatch_rc="$(read_rc "$aros_root/abbstools-doorcheck-mismatch-rc.txt")"
missing_rc="$(read_rc "$aros_root/abbstools-doorcheck-missing-rc.txt")"

status=FAIL
observation=guest_tool_failure
if [[ "$started" == 1 && "$done_stage" == 1 && "$match_rc" == "0" && "$mismatch_rc" == "5" && "$missing_rc" == "5" ]] \
   && [[ -f "$match_out" && -f "$mismatch_out" && -f "$missing_out" ]] \
   && tr -d '\r' < "$match_out" | grep -q '^STATUS=OK$' \
   && tr -d '\r' < "$match_out" | grep -q '^EXPECTED_TYPE=FILE$' \
   && tr -d '\r' < "$match_out" | grep -q '^ACTUAL_TYPE=FILE$' \
   && tr -d '\r' < "$match_out" | grep -q '^RESULT=MATCH$' \
   && tr -d '\r' < "$mismatch_out" | grep -q '^STATUS=WARN$' \
   && tr -d '\r' < "$mismatch_out" | grep -q '^EXPECTED_TYPE=DIRECTORY$' \
   && tr -d '\r' < "$mismatch_out" | grep -q '^ACTUAL_TYPE=FILE$' \
   && tr -d '\r' < "$mismatch_out" | grep -q '^RESULT=TYPE_MISMATCH$' \
   && tr -d '\r' < "$missing_out" | grep -q '^STATUS=WARN$' \
   && tr -d '\r' < "$missing_out" | grep -q '^PRESENT=NO$' \
   && tr -d '\r' < "$missing_out" | grep -q '^RESULT=PATH_NOT_PRESENT$'; then
  status=PASS
  observation=guest_executed_doorcheck_match_mismatch_missing_matrix
elif [[ "$started" != 1 ]]; then
  observation=guest_startup_not_reached
elif [[ "$done_stage" != 1 ]]; then
  observation=guest_stopped_in_doorcheck
elif [[ "$match_rc" != "0" || "$mismatch_rc" != "5" || "$missing_rc" != "5" ]]; then
  observation=doorcheck_unexpected_rc
else
  observation=doorcheck_contract_mismatch
fi

{
  echo "STATUS=$status"
  echo "GATE=M4_2_AROS_DOORCHECK"
  echo "MODEL=A1200"
  echo "KICKSTART=internal"
  echo "FS_UAE_EXIT=$fs_rc"
  echo "FIXTURE_FILE=SYS:ABBSToolsTest/door.bin"
  echo "FIXTURE_DIRECTORY=SYS:ABBSToolsTest/DoorDir"
  echo "FIXTURE_MISSING=SYS:ABBSToolsTest/missing-door.bin"
  echo "STAGE_STARTED=$started"
  echo "STAGE_DONE=$done_stage"
  echo "MATCH_RC=$match_rc"
  echo "MISMATCH_RC=$mismatch_rc"
  echo "MISSING_RC=$missing_rc"
  echo "OBSERVATION=$observation"
  [[ -f "$match_out" ]] && tr -d '\r' < "$match_out" | sed 's/^/MATCH_OUTPUT=/'
  [[ -f "$mismatch_out" ]] && tr -d '\r' < "$mismatch_out" | sed 's/^/MISMATCH_OUTPUT=/'
  [[ -f "$missing_out" ]] && tr -d '\r' < "$missing_out" | sed 's/^/MISSING_OUTPUT=/'
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
