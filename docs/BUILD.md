# Building libtorrent_dart

This document covers building the native shared libraries from source. Pre-built
binaries for macOS and Android (arm64-v8a) are checked in under `binaries/`.

## Prerequisites

### All platforms

- CMake 3.20+
- Ninja build system (`brew install ninja` / `apt install ninja-build`)
- Boost headers 1.80+ (headers only — no compiled Boost libraries needed)

### macOS

- Xcode Command Line Tools (`xcode-select --install`)
- Homebrew packages:
  ```
  brew install cmake ninja boost openssl
  ```
- Tested with: AppleClang 17, Boost 1.90.0, OpenSSL 3.6.1

### Android

- Android NDK r25 or later (tested with NDK 27.0.12077973)
  ```
  brew install --cask android-ndk
  # or download from https://developer.android.com/ndk/downloads
  ```
- Set `ANDROID_NDK_HOME` to the NDK root, e.g.:
  ```
  export ANDROID_NDK_HOME=/opt/homebrew/share/android-ndk
  ```
- Boost headers accessible from the host (same as macOS path above)
- OpenSSL is **not** required for Android — the build will disable encryption
  support automatically if not found

## Initialise the submodule

The libtorrent source is included as a git submodule with nested sub-submodules.
Run this once after cloning:

```sh
git -c protocol.file.allow=always submodule update --init --recursive thirdparty/libtorrent
```

## macOS

```sh
cmake -G Ninja -S . -B cmake_build/macos \
  -DCMAKE_BUILD_TYPE=Release \
  -DLTD_BOOST_HEADERS_ROOT=/opt/homebrew/include

cmake --build cmake_build/macos --target libtorrent_dart -j$(sysctl -n hw.logicalcpu)
```

Output (placed in `binaries/macos/` automatically):

| File                             | Description                                            |
| -------------------------------- | ------------------------------------------------------ |
| `libtorrent-rasterbar.dylib`     | FFI wrapper — loaded by Dart                           |
| `libtorrent-rasterbar.2.0.dylib` | libtorrent core — loaded at runtime via `@loader_path` |

If Boost is installed somewhere other than `/opt/homebrew/include`, pass the
correct path via `-DLTD_BOOST_HEADERS_ROOT=<path>`.

## Android (arm64-v8a)

The Android build links libtorrent **statically** into the wrapper, producing a
single self-contained `.so` with no dependency on a second libtorrent `.so`.

```sh
cmake -G Ninja -S . -B cmake_build/android \
  -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-24 \
  -DCMAKE_BUILD_TYPE=Release \
  -DLTD_BOOST_HEADERS_ROOT=/opt/homebrew/include \
  -DBUILD_SHARED_LIBS=OFF

cmake --build cmake_build/android --target libtorrent_dart -j$(sysctl -n hw.logicalcpu)
```

Output: `binaries/android/libtorrent-rasterbar.so` (~87 MB unstripped; will be
stripped automatically by the Android Gradle build pipeline for release APKs).

To build for other ABIs, change `-DANDROID_ABI=` to one of:
`armeabi-v7a`, `x86`, `x86_64`.

## CMake options

| Option                   | Default                 | Description                                                       |
| ------------------------ | ----------------------- | ----------------------------------------------------------------- |
| `LTD_BOOST_HEADERS_ROOT` | `/opt/homebrew/include` | Directory containing `boost/` headers                             |
| `LTD_OUTPUT_DIR`         | `<repo>/binaries`       | Root directory for platform output subdirectories                 |
| `BUILD_SHARED_LIBS`      | `ON`                    | Set to `OFF` to link libtorrent statically (required for Android) |

## Running the Dart tests

### Dart SDK requirement

This package uses the **Native Assets** feature, which requires the **standalone
Dart SDK** (3.11.0 or later). The Flutter-bundled `dart` binary on the `stable`
channel blocks this feature; do not use it for development.

Install the standalone SDK via Homebrew:

```sh
brew install dart-sdk
```

Verify the correct binary is on your PATH (`/opt/homebrew/bin/dart` from the
`dart-sdk` formula, not Flutter's):

```sh
dart --version
# Dart SDK version: 3.11.0 (stable) ...
```

### Running the tests

After a successful macOS build and installing the standalone SDK:

```sh
dart pub get
dart test
```

All 3 tests should pass in under 15 seconds.
