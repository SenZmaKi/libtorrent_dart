# libtorrent_dart

Dart bindings for [libtorrent-rasterbar](https://github.com/arvidn/libtorrent).

This package exposes two entry points:

- High-level wrapper API: `package:libtorrent_dart/libtorrent_dart.dart`
- Low-level FFI API: `package:libtorrent_dart/libtorrent_dart_ffi.dart`

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

## Usage

Check out the [example](example/example.dart) for a quick start.

## Libtorrent API parity

Libtorrent API parity is tracked in:

- [LIBTORRENT_API_PARITY.md](docs/LIBTORRENT_API_PARITY.md)

## Build

Build instructions for all supported platforms (macOS, Linux, Windows, Android, iOS) are in:

- [BUILD.md](docs/BUILD.md)
