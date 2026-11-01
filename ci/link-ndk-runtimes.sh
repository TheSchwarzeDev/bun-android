#!/usr/bin/env bash
set -euo pipefail

: "${ANDROID_NDK_ROOT:?ANDROID_NDK_ROOT must point at the pinned NDK}"

LLVM_DIR="${LLVM_DIR:-$HOME/llvm21}"
CLANG="$LLVM_DIR/bin/clang"

NDK_CLANG_DIR="$ANDROID_NDK_ROOT/toolchains/llvm/prebuilt/linux-x86_64/lib/clang"
NDK_VER_DIR=$(ls "$NDK_CLANG_DIR" | head -n 1)
NDK_RT="$NDK_CLANG_DIR/$NDK_VER_DIR/lib/linux"

RES=$("$CLANG" -print-resource-dir)

echo "LLVM clang: $CLANG"
echo "LLVM resource dir: $RES"
echo "NDK clang version: $NDK_VER_DIR"

for A in aarch64 x86_64; do
    BUILTINS="$NDK_RT/libclang_rt.builtins-${A}-android.a"
    UNWIND="$NDK_RT/$A/libunwind.a"

    if [ ! -f "$BUILTINS" ]; then
        echo "Missing NDK runtime: $BUILTINS"
        exit 1
    fi

    if [ ! -f "$UNWIND" ]; then
        echo "Missing NDK unwind library: $UNWIND"
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

echo "Checking required ARM64 runtime:"
ls -l "$RES/lib/aarch64-unknown-linux-android28/libclang_rt.builtins.a"

echo "link-ndk-runtimes: OK"
