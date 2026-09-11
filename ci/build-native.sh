#!/usr/bin/env bash
set -euo pipefail

IMAGE="${ABBSTOOLS_BEBBO_IMAGE:-amigadev/m68k-amigaos-gcc@sha256:b18080e6ffca8f793e0f539536a9138e9d2a548ca1a301c7483f43ee15fedfed}"
OUT_DIR="${1:-build/qualification/native}"
PULL_TIMEOUT="${ABBSTOOLS_DOCKER_PULL_TIMEOUT:-180}"
BUILD_TIMEOUT="${ABBSTOOLS_DOCKER_BUILD_TIMEOUT:-120}"

mkdir -p "$OUT_DIR" build

printf 'IMAGE=%s\n' "$IMAGE"
printf 'PULL_TIMEOUT=%ss\n' "$PULL_TIMEOUT"
printf 'BUILD_TIMEOUT=%ss\n' "$BUILD_TIMEOUT"

echo 'STEP=docker-pull'
timeout "${PULL_TIMEOUT}s" docker pull "$IMAGE"

echo 'STEP=docker-inspect'
docker image inspect "$IMAGE" --format '{{join .RepoDigests "\n"}}' | tee "$OUT_DIR/toolchain-image.txt"

echo 'STEP=compiler-version'
timeout 30s docker run --rm "$IMAGE" m68k-amigaos-gcc --version | tee "$OUT_DIR/compiler-version.txt"

echo 'STEP=static-gates'
python3 tests/check_m1_1.py
python3 tests/check_m1_2.py
python3 tests/check_m1_3a.py
python3 tests/check_m2_1.py
python3 tests/check_m2_2.py
python3 tests/check_m2_3.py
python3 tests/check_m2_4.py
python3 tests/check_m3_1.py
python3 tests/check_m3_2.py
python3 tests/check_m3_3.py
python3 tests/check_m3_4.py

compile_tool() {
  local tool="$1"
  shift
  echo "STEP=native-build-$tool"
  rm -f "build/$tool"
  timeout "${BUILD_TIMEOUT}s" docker run --rm -v "$PWD:/work" -w /work "$IMAGE" \
    m68k-amigaos-gcc \
      -Iinclude \
      -Os -Wall -Wextra -Werror \
      -m68000 -fomit-frame-pointer -noixemul \
      -o "build/$tool" \
      "$@" \
      -noixemul
}

compile_tool RexxPorts src/common/output.c src/tools/rexxports/main.c
compile_tool RexxProbe src/common/output.c src/common/arexx.c src/tools/rexxprobe/main.c
compile_tool NodeInfo src/common/output.c src/common/abbs.c src/tools/nodeinfo/main.c
compile_tool NodeWatch src/common/output.c src/common/abbs.c src/tools/nodewatch/main.c
compile_tool NodeCheck src/common/output.c src/common/abbs.c src/tools/nodecheck/main.c
compile_tool AssignCheck src/common/output.c src/tools/assigncheck/main.c
compile_tool BBSDoctor src/common/output.c src/common/abbs.c src/tools/bbsdoctor/main.c
compile_tool LastCalls src/common/output.c src/tools/lastcalls/main.c
compile_tool LogInfo src/common/output.c src/tools/loginfo/main.c
compile_tool UserInfo src/common/output.c src/common/abbs_user.c src/tools/userinfo/main.c
compile_tool ConfInfo src/common/output.c src/common/abbs_conf.c src/tools/confinfo/main.c

build_trace_tool() {
  local tool="$1"
  local source="$2"
  shift 2
  echo "STEP=native-build-${tool}Trace"
  rm -f "build/${tool}Trace"
  timeout "${BUILD_TIMEOUT}s" docker run --rm -v "$PWD:/work" -w /work "$IMAGE" \
    m68k-amigaos-gcc \
      -Iinclude -DABBSTOOLS_CI_TRACE=1 \
      -Os -Wall -Wextra -Werror \
      -m68000 -fomit-frame-pointer -noixemul \
      -o "build/${tool}Trace" \
      src/common/output.c \
      "$@" \
      "$source" \
      -noixemul
  cp "build/${tool}Trace" "$OUT_DIR/${tool}Trace"
}

build_trace_tool NodeInfo src/tools/nodeinfo/main.c src/common/abbs.c
build_trace_tool NodeWatch src/tools/nodewatch/main.c src/common/abbs.c
build_trace_tool NodeCheck src/tools/nodecheck/main.c src/common/abbs.c
build_trace_tool AssignCheck src/tools/assigncheck/main.c
build_trace_tool BBSDoctor src/tools/bbsdoctor/main.c src/common/abbs.c
build_trace_tool LastCalls src/tools/lastcalls/main.c
build_trace_tool LogInfo src/tools/loginfo/main.c
build_trace_tool UserInfo src/tools/userinfo/main.c
build_trace_tool ConfInfo src/tools/confinfo/main.c

echo 'STEP=validate-binaries'
: > "$OUT_DIR/file.txt"
: > "$OUT_DIR/checksums.sha256"
for tool in RexxPorts RexxProbe NodeInfo NodeWatch NodeCheck AssignCheck BBSDoctor LastCalls LogInfo UserInfo ConfInfo NodeInfoTrace NodeWatchTrace NodeCheckTrace AssignCheckTrace BBSDoctorTrace LastCallsTrace LogInfoTrace UserInfoTrace ConfInfoTrace; do
  test -s "build/$tool"
  cp "build/$tool" "$OUT_DIR/$tool"
  file "$OUT_DIR/$tool" | tee -a "$OUT_DIR/file.txt"
  sha256sum "$OUT_DIR/$tool" | tee -a "$OUT_DIR/checksums.sha256"
  if ! file "$OUT_DIR/$tool" | grep -Eiq 'AmigaOS|Amiga.*executable|loadseg'; then
    echo "ERROR: $tool is not recognized as an Amiga executable" >&2
    exit 1
  fi
done

{
  echo 'STATUS=PASS'
  echo 'GATE=M3_4_NATIVE_BEBBO'
  echo "IMAGE=$IMAGE"
  echo "BINARY_REXXPORTS=$OUT_DIR/RexxPorts"
  echo "BINARY_REXXPROBE=$OUT_DIR/RexxProbe"
  echo "BINARY_NODEINFO=$OUT_DIR/NodeInfo"
  echo "BINARY_NODEWATCH=$OUT_DIR/NodeWatch"
  echo "BINARY_NODECHECK=$OUT_DIR/NodeCheck"
  echo "BINARY_ASSIGNCHECK=$OUT_DIR/AssignCheck"
  echo "BINARY_BBSDOCTOR=$OUT_DIR/BBSDoctor"
  echo "BINARY_LASTCALLS=$OUT_DIR/LastCalls"
  echo "BINARY_LOGINFO=$OUT_DIR/LogInfo"
  echo "BINARY_USERINFO=$OUT_DIR/UserInfo"
  echo "BINARY_CONFINFO=$OUT_DIR/ConfInfo"
  echo "BINARY_NODEINFO_TRACE=$OUT_DIR/NodeInfoTrace"
  echo "BINARY_NODEWATCH_TRACE=$OUT_DIR/NodeWatchTrace"
  echo "BINARY_NODECHECK_TRACE=$OUT_DIR/NodeCheckTrace"
  echo "BINARY_ASSIGNCHECK_TRACE=$OUT_DIR/AssignCheckTrace"
  echo "BINARY_BBSDOCTOR_TRACE=$OUT_DIR/BBSDoctorTrace"
  echo "BINARY_LASTCALLS_TRACE=$OUT_DIR/LastCallsTrace"
  echo "BINARY_LOGINFO_TRACE=$OUT_DIR/LogInfoTrace"
  echo "BINARY_USERINFO_TRACE=$OUT_DIR/UserInfoTrace"
  echo "BINARY_CONFINFO_TRACE=$OUT_DIR/ConfInfoTrace"
} | tee "$OUT_DIR/result.txt"
