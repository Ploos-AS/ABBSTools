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

compile_tool RexxPorts \
  src/common/output.c \
  src/tools/rexxports/main.c

compile_tool RexxProbe \
  src/common/output.c \
  src/common/arexx.c \
  src/tools/rexxprobe/main.c

compile_tool NodeInfo \
  src/common/output.c \
  src/common/abbs.c \
  src/tools/nodeinfo/main.c

echo 'STEP=native-build-NodeInfoTrace'
rm -f build/NodeInfoTrace
timeout "${BUILD_TIMEOUT}s" docker run --rm -v "$PWD:/work" -w /work "$IMAGE" \
  m68k-amigaos-gcc \
    -Iinclude -DABBSTOOLS_CI_TRACE=1 \
    -Os -Wall -Wextra -Werror \
    -m68000 -fomit-frame-pointer -noixemul \
    -o build/NodeInfoTrace \
    src/common/output.c \
    src/common/abbs.c \
    src/tools/nodeinfo/main.c \
    -noixemul
cp build/NodeInfoTrace "$OUT_DIR/NodeInfoTrace"

echo 'STEP=validate-binaries'
: > "$OUT_DIR/file.txt"
: > "$OUT_DIR/checksums.sha256"
for tool in RexxPorts RexxProbe NodeInfo NodeInfoTrace; do
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
  echo 'GATE=M1_3A_NATIVE_BEBBO'
  echo "IMAGE=$IMAGE"
  echo "BINARY_REXXPORTS=$OUT_DIR/RexxPorts"
  echo "BINARY_REXXPROBE=$OUT_DIR/RexxProbe"
  echo "BINARY_NODEINFO=$OUT_DIR/NodeInfo"
  echo "BINARY_NODEINFO_TRACE=$OUT_DIR/NodeInfoTrace"
} | tee "$OUT_DIR/result.txt"
