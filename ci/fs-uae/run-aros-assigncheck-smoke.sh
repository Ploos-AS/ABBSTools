#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/aros-assigncheck}"
SYSTEM_DIR="build/fs-uae/aros-system"
NATIVE_DIR="build/qualification/native"
mkdir -p "$OUT_DIR"

if [[ ! -f "$NATIVE_DIR/AssignCheck" ]]; then
  echo "ERROR: native AssignCheck binary missing; run ci/build-native.sh first" >&2
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
mkdir -p "$tool_dir/BBS" "$tool_dir/ABBS"
cp "$NATIVE_DIR/AssignCheck" "$tool_dir/AssignCheck"

cp "$startup" "$startup.abbstools-original"
cat > "$startup" <<'EOF'
SYS:C/Echo "ABBSTOOLS_GUEST_STARTED=1" >SYS:abbstools-assigncheck-stage-started.txt

SYS:C/Assign BBS: SYS:ABBSToolsTest/BBS
SYS:C/Assign ABBS: SYS:ABBSToolsTest/ABBS
SYS:ABBSToolsTest/AssignCheck >SYS:abbstools-assigncheck-both.txt
SYS:C/Echo $RC >SYS:abbstools-assigncheck-both-rc.txt

SYS:C/Assign ABBS: REMOVE
SYS:ABBSToolsTest/AssignCheck >SYS:abbstools-assigncheck-bbs-only.txt
SYS:C/Echo $RC >SYS:abbstools-assigncheck-bbs-only-rc.txt

SYS:C/Assign BBS: REMOVE
SYS:ABBSToolsTest/AssignCheck >SYS:abbstools-assigncheck-none.txt
SYS:C/Echo $RC >SYS:abbstools-assigncheck-none-rc.txt

SYS:C/Echo "ABBSTOOLS_ASSIGNCHECK_DONE=1" >SYS:abbstools-assigncheck-stage-done.txt
SYS:C/Execute SYS:S/Startup-Sequence.abbstools-original
EOF

rm -f "$aros_root"/abbstools-assigncheck-*.txt

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true

set +e
timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae.log" 2>&1
fs_rc=$?
set -e

started=0
done_stage=0
[[ -f "$aros_root/abbstools-assigncheck-stage-started.txt" ]] && started=1
[[ -f "$aros_root/abbstools-assigncheck-stage-done.txt" ]] && done_stage=1

read_rc() {
  local file="$1"
  if [[ -f "$file" ]]; then
    tr -d '\r\n ' < "$file"
  fi
}

both_rc="$(read_rc "$aros_root/abbstools-assigncheck-both-rc.txt")"
bbs_only_rc="$(read_rc "$aros_root/abbstools-assigncheck-bbs-only-rc.txt")"
none_rc="$(read_rc "$aros_root/abbstools-assigncheck-none-rc.txt")"

both_out="$aros_root/abbstools-assigncheck-both.txt"
bbs_only_out="$aros_root/abbstools-assigncheck-bbs-only.txt"
none_out="$aros_root/abbstools-assigncheck-none.txt"

status=FAIL
observation=guest_tool_failure
if [[ "$started" == 1 && "$done_stage" == 1 \
      && "$both_rc" == "0" && "$bbs_only_rc" == "5" && "$none_rc" == "5" \
      && -f "$both_out" && -f "$bbs_only_out" && -f "$none_out" ]] \
   && tr -d '\r' < "$both_out" | grep -q '^BBS_PRESENT=1$' \
   && tr -d '\r' < "$both_out" | grep -q '^ABBS_PRESENT=1$' \
   && tr -d '\r' < "$both_out" | grep -q '^HEALTH=OK$' \
   && tr -d '\r' < "$both_out" | grep -q '^REASON=NONE$' \
   && tr -d '\r' < "$bbs_only_out" | grep -q '^BBS_PRESENT=1$' \
   && tr -d '\r' < "$bbs_only_out" | grep -q '^ABBS_PRESENT=0$' \
   && tr -d '\r' < "$bbs_only_out" | grep -q '^REASON=ABBS_NOT_PRESENT$' \
   && tr -d '\r' < "$none_out" | grep -q '^BBS_PRESENT=0$' \
   && tr -d '\r' < "$none_out" | grep -q '^ABBS_PRESENT=0$' \
   && tr -d '\r' < "$none_out" | grep -q '^REASON=BBS_AND_ABBS_NOT_PRESENT$'; then
  status=PASS
  observation=guest_executed_assigncheck_matrix
elif [[ "$started" != 1 ]]; then
  observation=guest_startup_not_reached
elif [[ "$done_stage" != 1 ]]; then
  observation=guest_stopped_in_assigncheck_matrix
else
  observation=assigncheck_contract_mismatch
fi

{
  echo "STATUS=$status"
  echo "GATE=M2_3_AROS_ASSIGNCHECK"
  echo "MODEL=A1200"
  echo "KICKSTART=internal"
  echo "FS_UAE_EXIT=$fs_rc"
  echo "STAGE_STARTED=$started"
  echo "STAGE_DONE=$done_stage"
  echo "BOTH_RC=$both_rc"
  echo "BBS_ONLY_RC=$bbs_only_rc"
  echo "NONE_RC=$none_rc"
  echo "OBSERVATION=$observation"
  for pair in BOTH:"$both_out" BBS_ONLY:"$bbs_only_out" NONE:"$none_out"; do
    label="${pair%%:*}"
    file="${pair#*:}"
    if [[ -f "$file" ]]; then
      tr -d '\r' < "$file" | sed "s/^/${label}=/"
    fi
  done
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
