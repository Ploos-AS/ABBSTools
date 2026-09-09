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

echo 'STEP=static-gate'
python3 tests/check_m1_1.py

echo 'STEP=native-build'
rm -f build/RexxPorts
set +e
timeout "${BUILD_TIMEOUT}s" docker run --rm -v "$PWD:/work" -w /work "$IMAGE" \
  m68k-amigaos-gcc \
    -Iinclude \
    -Os -Wall -Wextra -Werror \
    -m68000 -fomit-frame-pointer -noixemul \
    -o build/RexxPorts \
    src/common/output.c \
    src/tools/rexxports/main.c \
    -noixemul
rc=$?
set -e
if [[ $rc -ne 0 ]]; then
  echo "ERROR: native build failed or timed out (rc=$rc)" >&2
  exit "$rc"
fi

echo 'STEP=validate-binary'
test -s build/RexxPorts
cp build/RexxPorts "$OUT_DIR/RexxPorts"
file "$OUT_DIR/RexxPorts" | tee "$OUT_DIR/file.txt"
sha256sum "$OUT_DIR/RexxPorts" | tee "$OUT_DIR/checksums.sha256"

if ! file "$OUT_DIR/RexxPorts" | grep -Eiq 'AmigaOS|Amiga.*executable|loadseg'; then
  echo 'ERROR: RexxPorts is not recognized as an Amiga executable' >&2
  exit 1
fi

{
  echo 'STATUS=PASS'
  echo 'GATE=M1_1_NATIVE_BEBBO'
  echo "IMAGE=$IMAGE"
  echo "BINARY=$OUT_DIR/RexxPorts"
} | tee "$OUT_DIR/result.txt"
