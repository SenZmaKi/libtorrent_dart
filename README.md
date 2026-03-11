# libtorrent_dart

Dart FFI wrapper over [libtorrent-rasterbar](https://github.com/arvidn/libtorrent).

This package exposes two direct entry points:

- High-level wrapper API: `package:libtorrent_dart/src/libtorrent_dart.dart`
- Raw FFI API: `package:libtorrent_dart/src/libtorrent_dart_ffi.dart`

## Usage

### High-level API

```dart
import 'package:libtorrent_dart/src/libtorrent_dart.dart';

void main() {
  final session = createSession();
  final torrent = session.addMagnet(
    magnetUri: 'magnet:?xt=urn:btih:... ',
    savePath: '/tmp/downloads',
  );

  torrent.pause();
  torrent.resume();
  torrent.cancel(deleteFiles: false);
  session.close();
}
```

### Raw FFI API

```dart
import 'package:libtorrent_dart/src/libtorrent_dart_ffi.dart' as ffi;
```

## Build

Build instructions for all supported platforms (macOS, Linux, Windows, Android, iOS) are in:

- `docs/BUILD.md`

## API compatibility

Compatibility and bridge coverage notes are tracked in:

- `docs/API_COMPATIBILITY.md`
