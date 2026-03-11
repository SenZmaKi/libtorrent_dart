# Building libtorrent_dart

This guide covers building the native bridge for all supported targets.

## Versioned binary layout (important)

At load time, the Dart hook resolves the package version from `pubspec.yaml` and
loads binaries from this layout:

`binaries/<platform>/<package-version>/<binary-name>`

Example for package version `1.1.2` on Linux:

`binaries/linux/1.1.2/libtorrent-rasterbar.so`

This prevents accidentally loading stale binaries from an older package version.
When building manually, pass `-DLTD_BINARY_LAYOUT_VERSION=<package-version>` so
the output path matches what the hook will load.

## Prerequisites

- CMake 3.20+
- Ninja (`brew install ninja` / `apt install ninja-build`)
- Boost headers (1.80+)
- Clone the repository with submodules:

```sh
git clone --recursive https://github.com/SenZmaKi/libtorrent_dart.git
cd libtorrent_dart
```

## macOS

```sh
cmake -G Ninja -S . -B cmake_build/macos \
  -DCMAKE_BUILD_TYPE=Release \
  -DLTD_BOOST_HEADERS_ROOT=/opt/homebrew/include \
  -DLTD_BINARY_LAYOUT_VERSION=1.1.2
cmake --build cmake_build/macos --target libtorrent_dart -j8
```

Output: `binaries/macos/1.1.2/libtorrent-rasterbar.dylib`

## Linux

```sh
cmake -G Ninja -S . -B cmake_build/linux \
  -DCMAKE_BUILD_TYPE=Release \
  -DLTD_BOOST_HEADERS_ROOT=/usr/include \
  -DLTD_BINARY_LAYOUT_VERSION=1.1.2
cmake --build cmake_build/linux --target libtorrent_dart -j8
```

Output: `binaries/linux/1.1.2/libtorrent-rasterbar.so`

## Windows (MSVC)

```powershell
cmake -G "Ninja" -S . -B cmake_build/windows `
  -DCMAKE_BUILD_TYPE=Release `
  -DLTD_BINARY_LAYOUT_VERSION=1.1.2
cmake --build cmake_build/windows --target libtorrent_dart -j8
```

Output: `binaries/windows/1.1.2/torrent-rasterbar.dll`

## Android (NDK)

```sh
cmake -G Ninja -S . -B cmake_build/android \
  -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-24 \
  -DCMAKE_BUILD_TYPE=Release \
  -DLTD_BOOST_HEADERS_ROOT=/opt/homebrew/include \
  -DLTD_BINARY_LAYOUT_VERSION=1.1.2 \
  -DBUILD_SHARED_LIBS=OFF
cmake --build cmake_build/android --target libtorrent_dart -j8
```

Output: `binaries/android/1.1.2/libtorrent-rasterbar.so`

## iOS

```sh
cmake -G Xcode -S . -B cmake_build/ios \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0 \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DLTD_BOOST_HEADERS_ROOT=/opt/homebrew/include \
  -DLTD_BINARY_LAYOUT_VERSION=1.1.2 \
  -DCMAKE_BUILD_TYPE=Release
cmake --build cmake_build/ios --config Release --target libtorrent_dart
```

Output: `binaries/ios/1.1.2/Release/libtorrent-rasterbar.a`

## Dart checks

```sh
dart analyze
dart test
```
