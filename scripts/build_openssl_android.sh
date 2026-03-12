#!/usr/bin/env bash
# Cross-compile a static OpenSSL for Android arm64-v8a using the NDK.
# Runs on Linux (GitHub Actions ubuntu-latest) and Linux WSL.
#
# Produces:
#   thirdparty/openssl-android/arm64-v8a/
#       include/openssl/   (headers)
#       lib/libssl.a
#       lib/libcrypto.a
set -euo pipefail

OPENSSL_VERSION="${1:-3.4.1}"
NDK_HOME="${ANDROID_NDK_HOME:-${ANDROID_NDK_ROOT:-}}"
FORCE="${2:-}"

REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$REPO_ROOT/thirdparty/openssl-android/arm64-v8a"
TARBALL="/tmp/openssl-${OPENSSL_VERSION}.tar.gz"
SRC_DIR="/tmp/openssl-${OPENSSL_VERSION}"
BUILD_DIR="/tmp/openssl-android-build"

if [[ -f "$OUT_DIR/lib/libssl.a" && -z "$FORCE" ]]; then
    echo "Static OpenSSL already built at $OUT_DIR  (pass --force to rebuild)"
    exit 0
fi

if [[ -z "$NDK_HOME" ]]; then
    echo "Error: ANDROID_NDK_HOME is not set." >&2
    exit 1
fi

# Detect host platform (linux-x86_64 or darwin-x86_64 etc.)
HOST_TAG="$(uname -s | tr '[:upper:]' '[:lower:]')-x86_64"
TOOLCHAIN="$NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG/bin"
if [[ ! -f "$TOOLCHAIN/clang" && ! -f "$TOOLCHAIN/clang.exe" ]]; then
    # The NDK supplied might be the Windows variant (windows-x86_64).
    # Download the Linux NDK and use that instead.
    NDK_VERSION="r26c"
    LINUX_NDK_CACHE="/tmp/ndk-linux-$NDK_VERSION"
    if [[ ! -f "$LINUX_NDK_CACHE/toolchains/llvm/prebuilt/linux-x86_64/bin/clang" ]]; then
        echo "NDK toolchain not found at $TOOLCHAIN."
        echo "Downloading Android NDK $NDK_VERSION for Linux (~650 MB, cached at $LINUX_NDK_CACHE)..."
        NDK_ZIP="/tmp/android-ndk-${NDK_VERSION}-linux.zip"
        curl -fL "https://dl.google.com/android/repository/android-ndk-${NDK_VERSION}-linux.zip" -o "$NDK_ZIP"
        mkdir -p "$(dirname "$LINUX_NDK_CACHE")"
        unzip -q "$NDK_ZIP" -d /tmp
        mv "/tmp/android-ndk-${NDK_VERSION}" "$LINUX_NDK_CACHE"
        rm -f "$NDK_ZIP"
    else
        echo "Using cached Linux NDK at $LINUX_NDK_CACHE"
    fi
    NDK_HOME="$LINUX_NDK_CACHE"
    HOST_TAG="linux-x86_64"
    TOOLCHAIN="$NDK_HOME/toolchains/llvm/prebuilt/$HOST_TAG/bin"
fi

# Download
if [[ ! -f "$TARBALL" ]]; then
    echo "Downloading OpenSSL $OPENSSL_VERSION ..."
    curl -fL "https://www.openssl.org/source/openssl-${OPENSSL_VERSION}.tar.gz" -o "$TARBALL"
fi

if [[ ! -d "$SRC_DIR" ]]; then
    echo "Extracting ..."
    tar -xzf "$TARBALL" -C /tmp
fi

# Configure
export ANDROID_NDK_HOME="$NDK_HOME"
export ANDROID_NDK_ROOT="$NDK_HOME"
export PATH="$TOOLCHAIN:$PATH"

rm -rf "$BUILD_DIR"
cp -r "$SRC_DIR" "$BUILD_DIR"
cd "$BUILD_DIR"

echo ""
echo "Configuring OpenSSL $OPENSSL_VERSION for android-arm64 ..."
perl Configure android-arm64 \
    no-shared \
    no-tests \
    --prefix="$OUT_DIR" \
    --openssldir="$OUT_DIR/ssl" \
    -D__ANDROID_API__=24

echo ""
echo "Building (this takes a few minutes) ..."
make -j"$(nproc)" build_libs
make install_dev

# Verify
for f in lib/libssl.a lib/libcrypto.a include/openssl/ssl.h; do
    if [[ ! -f "$OUT_DIR/$f" ]]; then
        echo "Error: expected output not found: $OUT_DIR/$f" >&2
        exit 1
    fi
done

ssl_mb=$(du -m "$OUT_DIR/lib/libssl.a"    | cut -f1)
cry_mb=$(du -m "$OUT_DIR/lib/libcrypto.a" | cut -f1)
echo ""
echo "Done!  libssl.a=${ssl_mb}MB  libcrypto.a=${cry_mb}MB"
echo "OPENSSL_ROOT_DIR => $OUT_DIR"
