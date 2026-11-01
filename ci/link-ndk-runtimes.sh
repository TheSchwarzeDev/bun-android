#!/usr/bin/env bash
set -euo pipefail

: "${ANDROID_NDK_ROOT:?ANDROID_NDK_ROOT must point at the pinned NDK}"

# Use the exact LLVM C++ driver used by the failing link command.
LLVM_CXX="${LLVM_CXX:-/usr/lib/llvm-21/bin/clang++}"

if [ ! -x "$LLVM_CXX" ]; then
    echo "Expected LLVM C++ driver not found: $LLVM_CXX" >&2
    exit 1
fi

NDK_CLANG_DIR="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/lib/clang"
NDK_VER_DIR=$(find "$NDK_CLANG_DIR" -mindepth 1 -maxdepth 1 -type d -printf '%f\n' | sort -V | tail -n 1)
NDK_RT="$NDK_CLANG_DIR/$NDK_VER_DIR/lib/linux"

RES=$("$LLVM_CXX" -print-resource-dir)

echo "LLVM C++ driver: $LLVM_CXX"
echo "LLVM resource dir: $RES"
echo "NDK clang version: $NDK_VER_DIR"
echo "NDK runtime directory: $NDK_RT"

for A in aarch64 x86_64; do
    BUILTINS="$NDK_RT/libclang_rt.builtins-${A}-android.a"
    UNWIND="$NDK_RT/$A/libunwind.a"

    if [ ! -f "$BUILTINS" ]; then
        echo "Missing NDK runtime: $BUILTINS" >&2
        find "$ANDROID_NDK_ROOT" -name "libclang_rt.builtins*${A}*" -print
        exit 1
    fi

    if [ ! -f "$UNWIND" ]; then
        echo "Missing NDK unwind library: $UNWIND" >&2
        find "$ANDROID_NDK_ROOT" -name libunwind.a -print
        exit 1
    fi

    mkdir -p "$RES/lib/linux/$A"
    ln -sf "$BUILTINS" "$RES/lib/linux/"
    ln -sf "$UNWIND" "$RES/lib/linux/$A/"

    DIR="$RES/lib/${A}-unknown-linux-android28"
    mkdir -p "$DIR"
    ln -sf "$BUILTINS" "$DIR/libclang_rt.builtins.a"
    ln -sf "$UNWIND" "$DIR/libunwind.a"
done

EXPECTED="$RES/lib/aarch64-unknown-linux-android28/libclang_rt.builtins.a"

echo "Checking required ARM64 runtime:"
ls -la "$EXPECTED"
test -f "$EXPECTED"
readlink -f "$EXPECTED"

echo "link-ndk-runtimes: OK"
