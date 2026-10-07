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

The source build hook downloads directly from release-asset URLs, follows
redirects, and reports HTTP failures without querying GitHub's release API.
This download change will reach hosted consumers in the next package release.

## Usage

Works with standalone Dart and Flutter (Dart 3.10 or newer).

```dart
import 'package:libtorrent_dart/libtorrent_dart.dart';

final session = createSession();
try {
  final torrent = session.addMagnet(
    magnetUri: 'magnet:?xt=urn:btih:...',
    savePath: '/path/to/downloads',
  );
  print(torrent.getStatus().progress);
} finally {
  session.close();
}
```

Check out the [CLI example](example/example.dart) and
[Flutter example](mobile_test/README.md) for progress reporting and cleanup.
The high-level API covers torrent controls, file/piece priorities, trackers,
resume data, session state, proxies, and session settings. It is a targeted
binding, not a complete mirror of every libtorrent C++ class.

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

## Piece reads and streaming (1.1.0)

Version 1.1.0 includes `TorrentHandle.pieceLength`, `numPieces`
and `pieceSize`, plus `Session.popAlertInfo(includePieceData: true)`. The latter
copies `read_piece_alert` data into owned Dart bytes and includes its piece index,
torrent ID and native error code. Keep one alert consumer per session. Native
reads are asynchronous; do not mix polling consumers that might consume each
other's completions. Metadata must be available before querying piece layout.
Use `readPiece` to request a read and check the resulting alert's `pieceError`
before consuming its `pieceData`. File/piece priorities and piece deadlines
provide the primitives for a streaming scheduler; this package does not supply
an HTTP server or media-player URL.

Published 1.1.0 native assets include these APIs. When changing the C++ bridge
locally, rebuild the matching native artifact; selecting this checkout with a
Dart path dependency does not rebuild C++.

The native bridge retains each popped alert batch until all its events have been
consumed. Generic session settings supplied to creation are now applied before
startup, including loopback listening and disabled discovery for controlled tests.

## Concurrency and verification

The native bridge has process-wide handle, progress-callback, and pending-alert
registries without synchronization. Route binding calls through one owning
isolate/thread; separate sessions do not make concurrent isolate access safe.
Cancel progress subscriptions before removing torrents or closing sessions.

`dart test` runs suites serially through `dart_test.yaml`. Desktop CI builds,
analyzes, and runs the Dart tests on x64 and ARM64. Android CI verifies native
builds; iOS CI verifies its archive and a native consumer link. These checks
do not establish mobile runtime behavior or public-swarm playback performance.
