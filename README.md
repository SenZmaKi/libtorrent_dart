# libtorrent_dart

Dart bindings for [libtorrent-rasterbar](https://github.com/arvidn/libtorrent).

This package exposes two entry points:

- High-level wrapper API: [`package:libtorrent_dart/libtorrent_dart.dart`](lib/libtorrent_dart.dart)
- Low-level FFI API: [`package:libtorrent_dart/libtorrent_dart_ffi.dart`](lib/libtorrent_dart_ffi.dart)

## Installation

```shell
dart pub add libtorrent_dart
```

The build hook downloads the required [native binary](https://github.com/SenZmaKi/libtorrent_dart/releases/latest) for the current package version, platform, and architecture. Native assets are bundled into the consuming application by Dart's build system.

## Usage

Check out the [example](example/example.dart) for a quick start.

## Libtorrent API parity

Libtorrent API parity is tracked in:

- [LIBTORRENT_API_PARITY.md](https://github.com/SenZmaKi/libtorrent_dart/blob/main/docs/LIBTORRENT_API_PARITY.md)

## Platforms

- Linux: ARM64 and x64.
- macOS: Apple silicon and Intel.
- Windows: ARM64 and x64.
- Android: ARMv7, ARM64, and x64.
- iOS: ARM64 (build/link validated; runtime untested).

## Build

Build instructions for all supported platforms (macOS, Linux, Windows, Android, iOS) are in:

- [BUILD.md](https://github.com/SenZmaKi/libtorrent_dart/blob/main/docs/BUILD.md)
