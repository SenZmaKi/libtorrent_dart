# Building libtorrent_dart

This guide covers building the native bridge for all supported targets.

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
  -DLTD_BOOST_HEADERS_ROOT=/opt/homebrew/include
cmake --build cmake_build/macos --target libtorrent_dart -j8
```

Output: `binaries/macos/libtorrent-rasterbar.dylib`

## Linux

```sh
cmake -G Ninja -S . -B cmake_build/linux \
  -DCMAKE_BUILD_TYPE=Release \
  -DLTD_BOOST_HEADERS_ROOT=/usr/include
cmake --build cmake_build/linux --target libtorrent_dart -j8
```

Output: `binaries/linux/libtorrent-rasterbar.so`

## Windows (MSVC)

```powershell
cmake -G "Ninja" -S . -B cmake_build/windows `
  -DCMAKE_BUILD_TYPE=Release
cmake --build cmake_build/windows --target libtorrent_dart -j8
```

Output: `binaries/windows/torrent-rasterbar.dll`

## Android (NDK)

```sh
cmake -G Ninja -S . -B cmake_build/android \
  -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-24 \
  -DCMAKE_BUILD_TYPE=Release \
  -DLTD_BOOST_HEADERS_ROOT=/opt/homebrew/include \
  -DBUILD_SHARED_LIBS=OFF
cmake --build cmake_build/android --target libtorrent_dart -j8
```

Output: `binaries/android/libtorrent-rasterbar.so`

## iOS

```sh
cmake -G Xcode -S . -B cmake_build/ios \
  -DCMAKE_SYSTEM_NAME=iOS \
  -DCMAKE_OSX_DEPLOYMENT_TARGET=13.0 \
  -DCMAKE_OSX_ARCHITECTURES=arm64 \
  -DLTD_BOOST_HEADERS_ROOT=/opt/homebrew/include \
  -DCMAKE_BUILD_TYPE=Release
cmake --build cmake_build/ios --config Release --target libtorrent_dart
```

Output: `binaries/ios/libtorrent-rasterbar.a`

## Dart checks

```sh
dart analyze
dart test
```
