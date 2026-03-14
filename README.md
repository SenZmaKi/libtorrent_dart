# libtorrent_dart

Dart bindings for [libtorrent-rasterbar](https://github.com/arvidn/libtorrent).

This package exposes two entry points:

- High-level wrapper API: [`package:libtorrent_dart/libtorrent_dart.dart`](lib/libtorrent_dart.dart)
- Low-level FFI API: [`package:libtorrent_dart/libtorrent_dart_ffi.dart`](lib/libtorrent_dart_ffi.dart)

## Installation

Add this to your `pubspec.yaml`:

```yaml
dependencies:
  libtorrent_dart:
    git:
      url: https://github.com/SenZmaKi/libtorrent_dart
      ref: main # or specify a commit/tag
```

Then run:

```bash
dart pub get
```
There is a build hook that attempts to download the required [binaries](https://github.com/SenZmaKi/libtorrent_dart/releases/latest) for the current platform and library version if they are not already present in the expected path.

## Usage

Check out the [example](example/example.dart) for a quick start.

## Libtorrent API parity

Libtorrent API parity is tracked in:

- [LIBTORRENT_API_PARITY.md](docs/LIBTORRENT_API_PARITY.md)

## Platforms

- Confirmed to work on Windows, Linux, and macOS.
- Should also work on Android and iOS, but these platforms have not yet been tested. This section will be updated once testing is completed.
- HTTPS torrents are currently not supported on iOS.
  
## Build

Build instructions for all supported platforms (macOS, Linux, Windows, Android, iOS) are in:

- [BUILD.md](docs/BUILD.md)
