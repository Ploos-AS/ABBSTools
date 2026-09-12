#!/usr/bin/env bash
set -euo pipefail

OUT_DIR="${1:-build/fs-uae/aros-tcpinfo}"
SYSTEM_DIR="build/fs-uae/aros-system"
NATIVE_DIR="build/qualification/native"
mkdir -p "$OUT_DIR"

if [[ ! -f "$NATIVE_DIR/TCPInfo" ]]; then
  echo "ERROR: native TCPInfo binary missing; run ci/build-native.sh first" >&2
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
cp "$NATIVE_DIR/TCPInfo" "$tool_dir/TCPInfo"

cp "$startup" "$startup.abbstools-original"
cat > "$startup" <<'EOF'
SYS:C/Echo "ABBSTOOLS_GUEST_STARTED=1" >SYS:abbstools-tcpinfo-stage-started.txt
SYS:ABBSToolsTest/TCPInfo definitely-missing.device 0 >SYS:abbstools-tcpinfo-missing.txt
SYS:C/Echo $RC >SYS:abbstools-tcpinfo-missing-rc.txt
SYS:ABBSToolsTest/TCPInfo definitely-missing.device invalid >SYS:abbstools-tcpinfo-invalid.txt
SYS:C/Echo $RC >SYS:abbstools-tcpinfo-invalid-rc.txt
SYS:C/Echo "ABBSTOOLS_AFTER_TCPINFO=1" >SYS:abbstools-tcpinfo-stage-after.txt
SYS:C/Execute SYS:S/Startup-Sequence.abbstools-original
EOF

rm -f "$aros_root"/abbstools-tcpinfo-*.txt

config="$OUT_DIR/aros-guest.fs-uae"
sed "s|@AROS_ROOT@|$PWD/$aros_root|" ci/fs-uae/aros-guest.fs-uae > "$config"
fs-uae --version > "$OUT_DIR/fs-uae-version.txt" 2>&1 || true

set +e
timeout 45s xvfb-run -a fs-uae "$config" > "$OUT_DIR/fs-uae.log" 2>&1
fs_rc=$?
set -e

missing="$aros_root/abbstools-tcpinfo-missing.txt"
invalid="$aros_root/abbstools-tcpinfo-invalid.txt"
missing_rc_file="$aros_root/abbstools-tcpinfo-missing-rc.txt"
invalid_rc_file="$aros_root/abbstools-tcpinfo-invalid-rc.txt"
started=0
after=0
[[ -f "$aros_root/abbstools-tcpinfo-stage-started.txt" ]] && started=1
[[ -f "$aros_root/abbstools-tcpinfo-stage-after.txt" ]] && after=1
missing_rc=""
invalid_rc=""
[[ -f "$missing_rc_file" ]] && missing_rc="$(tr -d '\r\n ' < "$missing_rc_file")"
[[ -f "$invalid_rc_file" ]] && invalid_rc="$(tr -d '\r\n ' < "$invalid_rc_file")"

status=FAIL
observation=guest_tool_failure
if [[ "$started" == 1 && "$after" == 1 && -f "$missing" && -f "$invalid" ]] \
   && tr -d '\r' < "$missing" | grep -q '^STATUS=WARN$' \
   && tr -d '\r' < "$missing" | grep -q '^DEVICE=definitely-missing.device$' \
   && tr -d '\r' < "$missing" | grep -q '^UNIT=0$' \
   && tr -d '\r' < "$missing" | grep -q '^AVAILABLE=NO$' \
   && tr -d '\r' < "$missing" | grep -q '^REASON=DEVICE_OPEN_FAILED$' \
   && [[ "$missing_rc" == "5" ]] \
   && tr -d '\r' < "$invalid" | grep -q '^Usage: TCPInfo \[DEVICE \[UNIT\]\]$' \
   && [[ "$invalid_rc" == "10" ]]; then
  status=PASS
  observation=guest_executed_tcpinfo_missing_device_and_invalid_cli
elif [[ "$started" != 1 ]]; then
  observation=guest_startup_not_reached
elif [[ "$after" != 1 ]]; then
  observation=guest_stopped_in_tcpinfo
else
  observation=guest_completed_but_contract_mismatch
fi

{
  echo "STATUS=$status"
  echo "GATE=M5_1_AROS_TCPINFO"
  echo "MODEL=A1200"
  echo "KICKSTART=internal"
  echo "FS_UAE_EXIT=$fs_rc"
  echo "STAGE_STARTED=$started"
  echo "STAGE_AFTER=$after"
  echo "MISSING_DEVICE_RC=$missing_rc"
  echo "INVALID_CLI_RC=$invalid_rc"
  echo "LIVE_ABBSTCP_DEVICE=UNVERIFIED"
  echo "OBSERVATION=$observation"
  if [[ -f "$missing" ]]; then tr -d '\r' < "$missing" | sed 's/^/MISSING=/' ; fi
  if [[ -f "$invalid" ]]; then tr -d '\r' < "$invalid" | sed 's/^/INVALID=/' ; fi
} | tee "$OUT_DIR/result.txt"

[[ "$status" == PASS ]]
