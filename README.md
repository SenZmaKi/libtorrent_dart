# libtorrent_dart

Dart FFI wrapper over [libtorrent-rasterbar](https://github.com/arvidn/libtorrent).

Provides an ABI-compatible C shim (`src/c/library.cpp`) that exposes a
fixed-signature `extern "C"` API suitable for Dart FFI, wrapping `lt::session`,
`lt::torrent_handle`, and `lt::settings_pack`.

## Structure

```
libtorrent_dart/
├── CMakeLists.txt          # Build the FFI shared library
├── src/c/
│   ├── libtorrent.h        # Public C ABI header
│   └── library.cpp         # C++ implementation of the C ABI
├── thirdparty/
│   └── libtorrent/         # git submodule → arvidn/libtorrent
├── lib/
│   ├── libtorrent_dart.dart        # Public barrel
│   └── src/libtorrent_dart.dart    # FFI bindings implementation
├── example/example.dart
├── test/libtorrent_dart_test.dart
└── binaries/               # Prebuilt shared libraries per platform
    ├── macos/
    ├── linux/
    ├── android/
    └── windows/
```

## Usage

```dart
import 'package:libtorrent_dart/libtorrent_dart.dart';

Future<void> main() async {
  final api = await LibtorrentBindings.load();
  final session = api.createSession();

  final torrent = session.addMagnet(
    magnetUri: 'magnet:?xt=urn:btih:...',
    savePath: '/tmp/downloads',
    downloadRateLimit: 5000000,
    uploadRateLimit: 1000000,
  );

  session.setIntSetting(LibtorrentSettingsTag.connectionsLimit, 200);

  final sub = torrent.listenProgress(
    onData: (status) {
      print('progress=${(status.progress * 100).toStringAsFixed(1)}% '
          'down=${status.downloadRate} up=${status.uploadRate}');
    },
  );

  // torrent.pause();
  // torrent.resume();
  // torrent.cancel(deleteFiles: true);
  // sub.cancel();
  // session.close();
}
```

## Native library

`LibtorrentBindings.load()` resolves the prebuilt binary from the `binaries/`
directory relative to the package root, or relative to the current working
directory. You can override with:

```dart
LibtorrentBindings.load(libraryPath: '/path/to/libtorrent-rasterbar.dylib');
```

Expected paths per platform:

| Platform | Path |
|----------|------|
| macOS    | `binaries/macos/libtorrent-rasterbar.dylib` |
| Linux    | `binaries/linux/libtorrent-rasterbar.so` |
| Android  | `binaries/android/libtorrent-rasterbar.so` |
| Windows  | `binaries/windows/torrent-rasterbar.dll` |

## Build

### Prerequisites

- CMake ≥ 3.20
- Ninja (recommended)
- Boost headers (e.g. via Homebrew: `brew install boost`)
- OpenSSL (e.g. via Homebrew: `brew install openssl`)

### Initialize submodule

```sh
git submodule update --init --recursive
```

### macOS

```sh
cmake -G Ninja -S . -B cmake_build/macos -DCMAKE_BUILD_TYPE=Release
cmake --build cmake_build/macos
```

The compiled `libtorrent-rasterbar.dylib` is placed in `binaries/macos/`.

### Linux

```sh
cmake -G Ninja -S . -B cmake_build/linux -DCMAKE_BUILD_TYPE=Release
cmake --build cmake_build/linux
```

### Android (NDK)

```sh
cmake -G Ninja -S . -B cmake_build/android \
  -DCMAKE_TOOLCHAIN_FILE="$ANDROID_NDK_HOME/build/cmake/android.toolchain.cmake" \
  -DANDROID_ABI=arm64-v8a \
  -DANDROID_PLATFORM=android-24 \
  -DCMAKE_BUILD_TYPE=Release \
  -DLTD_BOOST_HEADERS_ROOT=/opt/homebrew/include
cmake --build cmake_build/android
```

### Override Boost headers path

```sh
cmake ... -DLTD_BOOST_HEADERS_ROOT=/path/to/boost/include
```

## Settings

Use `LibtorrentSettingsTag` constants with `session.setIntSetting()`,
`session.setBoolSetting()`, or `session.setStringSetting()`, and
`torrent.setIntSetting()` for per-torrent limits.

```dart
// Session-level limits
session.setIntSetting(LibtorrentSettingsTag.downloadRateLimit, 5_000_000);
session.setIntSetting(LibtorrentSettingsTag.uploadRateLimit, 1_000_000);
session.setIntSetting(LibtorrentSettingsTag.connectionsLimit, 200);

// Proxy
session.setIntSetting(LibtorrentSettingsTag.proxyType, 2); // SOCKS5
session.setIntSetting(LibtorrentSettingsTag.proxyPort, 1080);
session.setStringSetting(LibtorrentSettingsTag.proxyHostname, '127.0.0.1');
```
