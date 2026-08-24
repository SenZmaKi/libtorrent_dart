#!/usr/bin/env bash
set -euo pipefail

OPENSSL_VERSION="${1:-3.4.1}"
REPO_ROOT="$(cd "$(dirname "$0")/.." && pwd)"
OUT_DIR="$REPO_ROOT/thirdparty/openssl-ios/arm64"
WORK_DIR="${RUNNER_TEMP:-/tmp}/openssl-ios-$OPENSSL_VERSION"

if [[ -f "$OUT_DIR/lib/libssl.a" && -f "$OUT_DIR/lib/libcrypto.a" ]]; then
  echo "Static iOS OpenSSL already exists at $OUT_DIR"
  exit 0
fi

rm -rf "$WORK_DIR"
mkdir -p "$WORK_DIR"
curl -fL "https://www.openssl.org/source/openssl-$OPENSSL_VERSION.tar.gz" \
  -o "$WORK_DIR/openssl.tar.gz"
tar -xzf "$WORK_DIR/openssl.tar.gz" -C "$WORK_DIR"
cd "$WORK_DIR/openssl-$OPENSSL_VERSION"

SDK_PATH="$(xcrun --sdk iphoneos --show-sdk-path)"
perl Configure ios64-cross no-shared no-tests no-apps \
  --prefix="$OUT_DIR" --openssldir="$OUT_DIR/ssl" \
  -isysroot "$SDK_PATH" -miphoneos-version-min=13.0
make -j"$(sysctl -n hw.ncpu)" build_libs
make install_dev

test -f "$OUT_DIR/lib/libssl.a"
test -f "$OUT_DIR/lib/libcrypto.a"
lipo "$OUT_DIR/lib/libssl.a" -verify_arch arm64
lipo "$OUT_DIR/lib/libcrypto.a" -verify_arch arm64
