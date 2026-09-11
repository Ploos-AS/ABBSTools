#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/aros-userinfo}"
SYSTEM_DIR="build/fs-uae/aros-system"
NATIVE_DIR="build/qualification/native"
mkdir -p "$OUT_DIR"

if [[ ! -f "$NATIVE_DIR/UserInfoTrace" ]]; then
  echo "ERROR: native UserInfoTrace binary missing; run ci/build-native.sh first" >&2
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
cp "$NATIVE_DIR/UserInfoTrace" "$tool_dir/UserInfo"

cp "$startup" "$startup.abbstools-original"
cat > "$startup" <<'EOF'
SYS:C/Echo "ABBSTOOLS_GUEST_STARTED=1" >SYS:abbstools-userinfo-stage-started.txt
SYS:ABBSToolsTest/UserInfo "Per Ousdal" 42 512 >SYS:abbstools-userinfo-output.txt
SYS:C/Echo $RC >SYS:abbstools-userinfo-rc.txt
SYS:C/Echo "ABBSTOOLS_USERINFO_DONE=1" >SYS:abbstools-userinfo-stage-done.txt
SYS:C/Execute SYS:S/Startup-Sequence.abbstools-original
EOF

rm -f "$aros_root"/abbstools-userinfo-*.txt

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true

set +e
timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae.log" 2>&1
fs_rc=$?
set -e

started=0
done_stage=0
[[ -f "$aros_root/abbstools-userinfo-stage-started.txt" ]] && started=1
[[ -f "$aros_root/abbstools-userinfo-stage-done.txt" ]] && done_stage=1

read_rc() {
  local path="$1"
  [[ -f "$path" ]] && tr -d '\r\n ' < "$path" || true
}

output="$aros_root/abbstools-userinfo-output.txt"
rc="$(read_rc "$aros_root/abbstools-userinfo-rc.txt")"

status=FAIL
observation=guest_tool_failure
if [[ "$started" == 1 && "$done_stage" == 1 && "$rc" == "0" && -f "$output" ]] \
   && tr -d '\r' < "$output" | grep -q '^STATUS=OK$' \
   && tr -d '\r' < "$output" | grep -q '^NAME=Per Ousdal$' \
   && tr -d '\r' < "$output" | grep -q '^USER_NR=42$' \
   && tr -d '\r' < "$output" | grep -q '^RECORD_SIZE=512$'; then
  status=PASS
  observation=guest_executed_userinfo_trace_fixture
elif [[ "$started" != 1 ]]; then
  observation=guest_startup_not_reached
elif [[ "$done_stage" != 1 ]]; then
  observation=guest_stopped_in_userinfo
elif [[ "$rc" != "0" ]]; then
  observation=userinfo_unexpected_rc
else
  observation=userinfo_contract_mismatch
fi

{
  echo "STATUS=$status"
  echo "GATE=M3_3_AROS_USERINFO"
  echo "MODEL=A1200"
  echo "KICKSTART=internal"
  echo "FS_UAE_EXIT=$fs_rc"
  echo "FIXTURE_MODE=trace"
  echo "FIXTURE_USER=Per Ousdal"
  echo "FIXTURE_USER_NR=42"
  echo "FIXTURE_RECORD_SIZE=512"
  echo "STAGE_STARTED=$started"
  echo "STAGE_DONE=$done_stage"
  echo "USERINFO_RC=$rc"
  echo "OBSERVATION=$observation"
  [[ -f "$output" ]] && tr -d '\r' < "$output" | sed 's/^/OUTPUT=/'
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
