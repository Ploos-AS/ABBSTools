#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/aros-loginfo}"
SYSTEM_DIR="build/fs-uae/aros-system"
NATIVE_DIR="build/qualification/native"
mkdir -p "$OUT_DIR"

if [[ ! -f "$NATIVE_DIR/LogInfoTrace" ]]; then
  echo "ERROR: native LogInfoTrace binary missing; run ci/build-native.sh first" >&2
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
cp "$NATIVE_DIR/LogInfoTrace" "$tool_dir/LogInfo"

cat > "$tool_dir/node1logfile" <<'EOF'
23:40 09/08-26 Node setup ok.
23:41 09/08-26 Login: Per Ousdal (local)
23:42 Time used: 1
23:42 0 messages read.
23:42 09/08-26 Logout: Per Ousdal
00:10 10/08-26 Login: Alice Example (telnet)
00:20 10/08-26 Logout: Alice Example
EOF

cp "$startup" "$startup.abbstools-original"
cat > "$startup" <<'EOF'
SYS:C/Echo "ABBSTOOLS_GUEST_STARTED=1" >SYS:abbstools-loginfo-stage-started.txt
SYS:ABBSToolsTest/LogInfo 1 SYS:ABBSToolsTest/node1logfile >SYS:abbstools-loginfo-output.txt
SYS:C/Echo $RC >SYS:abbstools-loginfo-rc.txt
SYS:C/Echo "ABBSTOOLS_LOGINFO_DONE=1" >SYS:abbstools-loginfo-stage-done.txt
SYS:C/Execute SYS:S/Startup-Sequence.abbstools-original
EOF

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true

clear_guest_markers() {
  rm -f "$aros_root"/abbstools-loginfo-*.txt
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
  if [[ -f "$aros_root/abbstools-loginfo-stage-started.txt" ]]; then
    boot_started=1
    break
  fi
  echo "WARN: LogInfo guest startup marker missing after attempt $attempt; retrying once" >&2
done

started=0
done_stage=0
[[ -f "$aros_root/abbstools-loginfo-stage-started.txt" ]] && started=1
[[ -f "$aros_root/abbstools-loginfo-stage-done.txt" ]] && done_stage=1

read_rc() {
  local path="$1"
  [[ -f "$path" ]] && tr -d '\r\n ' < "$path" || true
}

output="$aros_root/abbstools-loginfo-output.txt"
rc="$(read_rc "$aros_root/abbstools-loginfo-rc.txt")"

status=FAIL
observation=guest_tool_failure
if [[ "$started" == 1 && "$done_stage" == 1 && "$rc" == "0" && -f "$output" ]] \
   && tr -d '\r' < "$output" | grep -q '^NODE=1$' \
   && tr -d '\r' < "$output" | grep -q '^LOG_PRESENT=YES$' \
   && tr -d '\r' < "$output" | grep -q '^LINES=7$' \
   && tr -d '\r' < "$output" | grep -q '^LOGIN_RECORDS=2$' \
   && tr -d '\r' < "$output" | grep -q '^LOGOUT_RECORDS=2$'; then
  status=PASS
  observation=guest_executed_loginfo_fixture
elif [[ "$started" != 1 ]]; then
  observation=guest_startup_not_reached_after_retry
elif [[ "$done_stage" != 1 ]]; then
  observation=guest_stopped_in_loginfo
elif [[ "$rc" != "0" ]]; then
  observation=loginfo_unexpected_rc
else
  observation=loginfo_contract_mismatch
fi

{
  echo "STATUS=$status"
  echo "GATE=M3_2_AROS_LOGINFO"
  echo "MODEL=A1200"
  echo "KICKSTART=internal"
  echo "FS_UAE_EXIT=$fs_rc"
  echo "FIXTURE_PATH_MODE=direct-path"
  echo "BOOT_ATTEMPT=$boot_attempt"
  echo "BOOT_STARTED=$boot_started"
  echo "STAGE_STARTED=$started"
  echo "STAGE_DONE=$done_stage"
  echo "LOGINFO_RC=$rc"
  echo "OBSERVATION=$observation"
  [[ -f "$output" ]] && tr -d '\r' < "$output" | sed 's/^/OUTPUT=/'
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
