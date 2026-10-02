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

### Local streaming experiment

The unreleased streaming bridge adds `TorrentHandle.pieceLength`, `numPieces`
and `pieceSize`, plus `Session.popAlertInfo(includePieceData: true)`. The latter
copies `read_piece_alert` data into owned Dart bytes and includes its piece index,
torrent ID and native error code. Keep one alert consumer per session. Native
reads are asynchronous; do not mix polling consumers that might consume each
other's completions. The optional API requires rebuilding the matching native
artifact; selecting this checkout with a Dart path dependency does not rebuild C++.

The native bridge retains each popped alert batch until all its events have been
consumed. Generic session settings supplied to creation are now applied before
startup, including loopback listening and disabled discovery for controlled tests.
