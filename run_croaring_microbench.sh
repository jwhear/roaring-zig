#!/usr/bin/env bash
set -euo pipefail

# Build and run CRoaring microbenchmarks using zig cc/c++.
#
# Usage:
#   ./run_croaring_microbench.sh [DATA_DIR] [google-benchmark args]
#
# Notes:
# - Clones CRoaring into .deps/CRoaring if missing; otherwise updates it.
# - Builds with CMake in .deps/CRoaring/build-zig using zig cc/c++.
# - Builds only the 'bench' target and runs it.
# - By default, filters out benchmarks whose names contain 'cpp' or 'Cpp'.

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
CROARING_REMOTE="https://github.com/RoaringBitmap/CRoaring.git"
CROARING_DIR="$SCRIPT_DIR/tmp-croaring"
BUILD_DIR="$CROARING_DIR/build-zig"
BUILD_TYPE="Release"

mkdir -p "$(dirname "$CROARING_DIR")"

if [[ -d "$CROARING_DIR/.git" ]]; then
  echo "[INFO] Updating CRoaring at $CROARING_DIR"
  git -C "$CROARING_DIR" fetch --tags --prune
  git -C "$CROARING_DIR" pull --ff-only || true
else
  echo "[INFO] Cloning CRoaring into $CROARING_DIR"
  git clone --depth=1 "$CROARING_REMOTE" "$CROARING_DIR"
fi

# Prefer Ninja if available
GENERATOR_SWITCHES=""
if command -v ninja >/dev/null 2>&1; then
  GENERATOR_SWITCHES="-G Ninja"
fi

# Ensure zig is available
if ! command -v zig >/dev/null 2>&1; then
  echo "[ERROR] zig not found in PATH. Install zig and retry." >&2
  exit 1
fi

# Configure with CMake using zig as the C/C++ compiler
mkdir -p "$BUILD_DIR"
echo "[INFO] Configuring CMake in $BUILD_DIR (BUILD_TYPE=$BUILD_TYPE)"
CC="zig cc" CXX="zig c++" \
  cmake -S "$CROARING_DIR" -B "$BUILD_DIR" \
  $GENERATOR_SWITCHES \
  -DCMAKE_BUILD_TYPE="$BUILD_TYPE" \
  -DENABLE_ROARING_MICROBENCHMARKS=ON

# Build microbenchmarks (C-only by default: build 'bench' target)
echo "[INFO] Building microbenchmarks (bench only)"
cmake --build "$BUILD_DIR" --config "$BUILD_TYPE" --target bench --parallel

# Locate executables (handle generator differences)
BENCH_BIN="$BUILD_DIR/microbenchmarks/bench"
[[ -x "$BUILD_DIR/bench" ]] && BENCH_BIN="$BUILD_DIR/bench"

if [[ ! -x "$BENCH_BIN" ]]; then
  echo "[ERROR] bench executable not found (looked in $BUILD_DIR)" >&2
  exit 1
fi

# Run benchmarks
echo "[INFO] Running bench (realdata)"

# Parse args: optional first positional DATA_DIR if it is a directory
DATA_ARG=""
if [[ $# -gt 0 && -d "$1" && "$1" != -* ]]; then
  DATA_ARG="$1"
  shift
  echo "[INFO] Using DATA_DIR=$DATA_ARG"
fi

# Add default filter unless user provided one
HAS_FILTER=0
for a in "$@"; do
  if [[ "$a" == --benchmark_filter* ]]; then
    HAS_FILTER=1
    break
  fi
done
DEFAULT_FILTER=""
if [[ $HAS_FILTER -eq 0 ]]; then
  # POSIX ERE: include only non-C++ microbenchmarks by explicit allowlist
  DEFAULT_FILTER='--benchmark_filter=^(SuccessiveIntersection(64|Cardinality(64)?)?|SuccessiveUnion(Cardinality(64)?|64)?|SuccessiveDifferenceCardinality(64)?|TotalUnion(Heap)?|RandomAccess(64)?|ToArray(64)?|IterateAll(64)?|ComputeCardinality(64)?|RankMany(Slow)?)$'
fi

"$BENCH_BIN" ${DATA_ARG:++"$DATA_ARG"} ${DEFAULT_FILTER:+"$DEFAULT_FILTER"} "$@"

echo "[INFO] Done."
