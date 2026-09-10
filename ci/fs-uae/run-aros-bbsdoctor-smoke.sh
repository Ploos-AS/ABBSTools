#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/aros-bbsdoctor}"
SYSTEM_DIR="build/fs-uae/aros-system"
NATIVE_DIR="build/qualification/native"
mkdir -p "$OUT_DIR"

if [[ ! -f "$NATIVE_DIR/BBSDoctorTrace" ]]; then
  echo "ERROR: native BBSDoctorTrace binary missing; run ci/build-native.sh first" >&2
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
mkdir -p "$tool_dir/BBS" "$tool_dir/ABBS" "$tool_dir/fixtures"
cp "$NATIVE_DIR/BBSDoctorTrace" "$tool_dir/BBSDoctor"
cp tests/fixtures/node_active.log "$tool_dir/fixtures/node_active.log"

cp "$startup" "$startup.abbstools-original"
cat > "$startup" <<'EOF'
SYS:C/Echo "ABBSTOOLS_GUEST_STARTED=1" >SYS:abbstools-bbsdoctor-stage-started.txt

SYS:ABBSToolsTest/BBSDoctor 1 SYS:ABBSToolsTest/BBS SYS:ABBSToolsTest/ABBS SYS:ABBSToolsTest/fixtures/node_active.log >SYS:abbstools-bbsdoctor-both.txt
SYS:C/Echo $RC >SYS:abbstools-bbsdoctor-both-rc.txt
SYS:C/Echo "ABBSTOOLS_BOTH_DONE=1" >SYS:abbstools-bbsdoctor-stage-both-done.txt

SYS:ABBSToolsTest/BBSDoctor 1 SYS:ABBSToolsTest/BBS SYS:ABBSToolsTest/MISSING-ABBS SYS:ABBSToolsTest/fixtures/node_active.log >SYS:abbstools-bbsdoctor-bbs-only.txt
SYS:C/Echo $RC >SYS:abbstools-bbsdoctor-bbs-only-rc.txt
SYS:C/Echo "ABBSTOOLS_BBS_ONLY_DONE=1" >SYS:abbstools-bbsdoctor-stage-bbs-only-done.txt

SYS:ABBSToolsTest/BBSDoctor 1 SYS:ABBSToolsTest/MISSING-BBS SYS:ABBSToolsTest/MISSING-ABBS SYS:ABBSToolsTest/fixtures/node_active.log >SYS:abbstools-bbsdoctor-none.txt
SYS:C/Echo $RC >SYS:abbstools-bbsdoctor-none-rc.txt
SYS:C/Echo "ABBSTOOLS_NONE_DONE=1" >SYS:abbstools-bbsdoctor-stage-none-done.txt

SYS:C/Echo "ABBSTOOLS_BBSDOCTOR_DONE=1" >SYS:abbstools-bbsdoctor-stage-done.txt
SYS:C/Execute SYS:S/Startup-Sequence.abbstools-original
EOF

rm -f "$aros_root"/abbstools-bbsdoctor-*.txt

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true

set +e
timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae.log" 2>&1
fs_rc=$?
set -e

has_stage() {
  local name="$1"
  [[ -f "$aros_root/abbstools-bbsdoctor-stage-$name.txt" ]] && echo 1 || echo 0
}
read_rc() {
  local file="$1"
  [[ -f "$file" ]] && tr -d '\r\n ' < "$file" || true
}

started="$(has_stage started)"
both_done="$(has_stage both-done)"
bbs_only_done="$(has_stage bbs-only-done)"
none_done="$(has_stage none-done)"
done_stage="$(has_stage done)"
both_rc="$(read_rc "$aros_root/abbstools-bbsdoctor-both-rc.txt")"
bbs_only_rc="$(read_rc "$aros_root/abbstools-bbsdoctor-bbs-only-rc.txt")"
none_rc="$(read_rc "$aros_root/abbstools-bbsdoctor-none-rc.txt")"

both_out="$aros_root/abbstools-bbsdoctor-both.txt"
bbs_only_out="$aros_root/abbstools-bbsdoctor-bbs-only.txt"
none_out="$aros_root/abbstools-bbsdoctor-none.txt"

status=FAIL
observation=guest_tool_failure
if [[ "$started" == 1 && "$done_stage" == 1 \
      && "$both_rc" == "5" && "$bbs_only_rc" == "5" && "$none_rc" == "5" \
      && -f "$both_out" && -f "$bbs_only_out" && -f "$none_out" ]] \
   && tr -d '\r' < "$both_out" | grep -q '^HEALTH=WARN$' \
   && tr -d '\r' < "$both_out" | grep -q '^REASON=PORT_NOT_PRESENT$' \
   && tr -d '\r' < "$both_out" | grep -q '^BBS_PRESENT=1$' \
   && tr -d '\r' < "$both_out" | grep -q '^ABBS_PRESENT=1$' \
   && tr -d '\r' < "$both_out" | grep -q '^NODE=1$' \
   && tr -d '\r' < "$both_out" | grep -q '^PRESENT=0$' \
   && tr -d '\r' < "$both_out" | grep -q '^STATE=OFFLINE$' \
   && tr -d '\r' < "$both_out" | grep -q '^LOG_PRESENT=1$' \
   && tr -d '\r' < "$both_out" | grep -q '^SESSION=ACTIVE$' \
   && tr -d '\r' < "$both_out" | grep -q '^USER=Test User$' \
   && tr -d '\r' < "$bbs_only_out" | grep -q '^REASON=ABBS_NOT_PRESENT$' \
   && tr -d '\r' < "$bbs_only_out" | grep -q '^BBS_PRESENT=1$' \
   && tr -d '\r' < "$bbs_only_out" | grep -q '^ABBS_PRESENT=0$' \
   && tr -d '\r' < "$none_out" | grep -q '^REASON=BBS_AND_ABBS_NOT_PRESENT$' \
   && tr -d '\r' < "$none_out" | grep -q '^BBS_PRESENT=0$' \
   && tr -d '\r' < "$none_out" | grep -q '^ABBS_PRESENT=0$'; then
  status=PASS
  observation=guest_executed_bbsdoctor_matrix_direct_paths
elif [[ "$started" != 1 ]]; then
  observation=guest_startup_not_reached
elif [[ "$both_done" != 1 ]]; then
  observation=guest_stopped_in_both_present_case
elif [[ "$bbs_only_done" != 1 ]]; then
  observation=guest_stopped_in_bbs_only_case
elif [[ "$none_done" != 1 ]]; then
  observation=guest_stopped_in_none_present_case
elif [[ "$done_stage" != 1 ]]; then
  observation=guest_stopped_after_bbsdoctor_matrix
else
  observation=bbsdoctor_contract_mismatch
fi

{
  echo "STATUS=$status"
  echo "GATE=M2_4_AROS_BBSDOCTOR"
  echo "MODEL=A1200"
  echo "KICKSTART=internal"
  echo "FS_UAE_EXIT=$fs_rc"
  echo "FIXTURE_PATH_MODE=direct"
  echo "STAGE_STARTED=$started"
  echo "STAGE_BOTH_DONE=$both_done"
  echo "STAGE_BBS_ONLY_DONE=$bbs_only_done"
  echo "STAGE_NONE_DONE=$none_done"
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
